# DNS and Service Reachability Debugging Guide

Document compiled based on my live debugging steps, with additional best practices reviewed from documentation (RFCs, systemd-resolved manuals, BIND documentation).

## Debugging Process

### Phase 1: Initial DNS Verification

1. **Inspect `/etc/resolv.conf`**
   - Check the configured DNS servers.

2. **Check active DNS settings with `resolvectl status`**
   - Confirm which DNS servers `systemd-resolved` is using.

3. **Test resolution via local stub resolver**
   - `dig internal.example.com`
   - Result: `NXDOMAIN`

4. **Test resolution directly against the internal DNS server**
   - `dig internal.example.com @192.168.112.2`
   - Result: `NXDOMAIN`

   **Analysis:**
   - The query was correctly sent to 192.168.112.2, but no DNS record was found.

5. **Test resolution against a public DNS server for comparison**
   - `dig internal.example.com @8.8.8.8`
   - Result: `NXDOMAIN` (Expected; public DNS should not know about internal hostnames)

**Phase 1 Conclusion:**

- The DNS record for `internal.example.com` is missing or incorrectly configured on the internal DNS server (192.168.112.2).

---

### Phase 2: Service Reachability Test

Assuming the correct IP address for `internal.example.com` is **192.168.1.100**, we test service connectivity directly.

1. **Check basic network connectivity**
   - `ping -c 4 192.168.112.2`
   - Result: Successful ping; 0% packet loss.

2. **Check if standard web ports are open**
   - HTTP port (80): `nc -zv 192.168.112.2 80` -> Connection refused.
   - HTTPS port (443): `nc -zv 192.168.112.2 443` -> Connection refused.

3. **Attempt HTTP/HTTPS requests using `curl` with `--resolve`**

   - **HTTP Test:**
     - `curl -v --resolve internal.example.com:80:192.168.112.2 http://internal.example.com`
     - Result: Connection refused.

   - **HTTPS Test:**
     - `curl -kv --resolve internal.example.com:443:192.168.112.2 https://internal.example.com`
     - Result: Connection refused.

---

### Phase 2: Simulated Successful Test Scenario

(Assuming correct DNS and service availability)

- **Ping Test:** Successful replies from 192.168.1.100.
- **Netcat (nc) Test:** Connections to ports 80 and 443 succeed.
- **Curl Test:**
  - HTTP: Returns `HTTP/1.1 200 OK`.
  - HTTPS: Returns `HTTP/2 200 OK` or `HTTP/1.1 200 OK`, skipping certificate verification.

---

### Phase 3: Trace the Issue - Possible Causes

#### 1. DNS Server Issues (192.168.112.2)
- **Missing Record:** `internal.example.com` A record missing.
- **Typo in Record:** Incorrect hostname or IP address.
- **Wrong Zone/View:** DNS zones/views misconfigured.
- **DNS Service Issues:** Zone file errors or service malfunction.
- **Replication Problems:** Data not properly synced from primary server.

#### 2. Client-Side Issues
- **Incorrect DNS Server Configuration:** (Unlikely; confirmed via `resolvectl`).
- **Local DNS Cache Issues:** Might require cache flush (`sudo resolvectl flush-caches`).
- **Incorrect `/etc/hosts` Entry:** Could override correct DNS behavior.

#### 3. Network Path Issues
- **Firewall Blocking DNS Traffic:** (Unlikely; direct queries succeeded).
- **Upstream DNS Server Problems:** Internal server dependencies broken.

#### 4. Configuration or Process Issues
- **Recent Changes:** New deployments, network changes, or cleanup scripts.
- **New Service Setup:** Record creation might have been missed.

---

### Phase 4: Confirming and Fixing Potential Causes

#### 1. Issues Directly on the DNS Server (192.168.112.2)

**Possibility: Missing Record**

- **How to Check:**
  - SSH into the DNS server (e.g., `ssh admin@192.168.112.2`).
  - Inspect the DNS zone file (`/etc/bind/zones/db.example.com` for BIND, `/etc/dnsmasq.d/internal-hosts.conf` for dnsmasq, etc.).
  - Use `grep internal.example.com /path/to/zone/file` or open the file with `less`/`nano`.
  - Run `dig internal.example.com @localhost` from the server.

- **How to Fix:**
  - Add the missing A record:
    ```
    internal    IN    A    192.168.1.100
    ```
  - If using BIND, increment the serial number.
  - Reload DNS service:
    - BIND: `sudo systemctl reload bind9`
    - dnsmasq: `sudo systemctl restart dnsmasq`
  - Verify with `dig internal.example.com` from the client.

**Possibility: Typo in Record**

- **How to Check:**
  - SSH into the server and inspect the zone file.
  - Look for typos like `internal.examplle.com` or wrong IP addresses.

- **How to Fix:**
  - Correct the typo.
  - Increment the serial number if using BIND.
  - Reload/restart the DNS service.
  - Verify with `dig` from the client.

**Possibility: Wrong Zone or View**

- **How to Check:**
  - Review DNS configs (`/etc/bind/named.conf.local`, `/etc/dnsmasq.conf`, etc.).
  - Ensure the record is in the correct zone.

- **How to Fix:**
  - Move the record to the correct zone if needed.
  - Adjust zone/view settings.
  - Reload DNS service.
  - Re-test with `dig`.

**Possibility: DNS Service Problems**

- **How to Check:**
  - Run `sudo systemctl status bind9` (or dnsmasq).
  - Check logs: `sudo journalctl -u bind9 | grep -i error`.
  - Validate zone files with `named-checkzone` (for BIND).

- **How to Fix:**
  - Fix any syntax errors.
  - Restart DNS service.
  - Re-test.

**Possibility: Replication Issues (if secondary server)**

- **How to Check:**
  - Review logs for replication errors.
  - Compare SOA serial numbers:
    ```
    dig SOA internal.example.com @localhost +short
    dig SOA internal.example.com @192.168.1.9 +short
    ```

- **How to Fix:**
  - Ensure zone transfers are allowed.
  - Fix any firewall/network issues.
  - Correct configs.
  - Restart service and verify replication.

#### 2. Client-Side Issues (Our Machine)

**Possibility: Wrong DNS Server Config**

- **How to Check:**
  - Use `resolvectl status`.
  - Inspect `/etc/netplan/*.yaml` or `/etc/NetworkManager/system-connections/`.

- **How to Fix:**
  - Correct DNS server IPs.
  - Apply changes (`sudo netplan apply` or `sudo nmcli con up`).

**Possibility: Stale Local DNS Cache**

- **How to Check:**
  - Difficult; flush cache to be sure.

- **How to Fix:**
  - `sudo resolvectl flush-caches`

**Possibility: Bad `/etc/hosts` Entry**

- **How to Check:**
  - `cat /etc/hosts | grep internal.example.com`

- **How to Fix:**
  - Edit `/etc/hosts`, correct or comment out bad entries.

#### 3. Network Path Issues (Affecting DNS)

**Possibility: Firewall Blocking DNS**

- **How to Check:**
  - Check UFW: `sudo ufw status`
  - Check iptables: `sudo iptables -L OUTPUT -n -v | grep 53`
  - Trace route to port 53: `sudo traceroute -T -p 53 192.168.112.2`

- **How to Fix:**
  - Allow DNS traffic locally.
  - Request firewall changes from the network team if needed.

#### 4. Configuration / Change Management Issues

**Possibility: Recent Changes**

- **How to Check:**
  - Review change history (Ansible, Terraform, etc.).
  - Ask team about recent changes.

- **How to Fix:**
  - Revert bad changes.
  - Correct missing records.

---

## Bonus Tasks

### Bonus Task 1: Configure a local /etc/hosts entry to bypass DNS for testing

#### 1. Edit the hosts file with the command:
```
sudo vim /etc/hosts
```
#### 2. Add this entry (using a hypothetical IP) on a new line:
```
192.168.1.100   internal.example.com
```

### Bonus Task 2: Show how to persist DNS server settings using systemd-resolved

#### 1. Edit the configuration file:
```
sudo vim /etc/systemd/resolved.conf
```
#### 2. Set DNS Servers:
   - Find the [Resolve] section.
   - Uncomment and edit the DNS= line to include the desired servers 
   ```
   [Resolve]
   DNS=192.168.112.2 8.8.8.8
   #FallbackDNS=1.1.1.1 8.8.4.4 9.9.9.9
   #...
   ```
#### 3. Restart systemd-resolved:
```
sudo systemctl restart systemd-resolved
```

---

## Summary

Primary suspicion falls on the internal DNS server configuration (192.168.112.2). The record for `internal.example.com` appears missing, incorrect, or otherwise unavailable.

Final Note: This troubleshooting guide is based on my review of the environment and research into best practices for BIND, dnsmasq, and Linux DNS setups. If needed, I'm happy to walk through any of these steps in detail.

