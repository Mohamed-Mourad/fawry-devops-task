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
     - `curl -v --resolve internal.example.com:80:192.168.1.100 http://internal.example.com`
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

## Summary

Primary suspicion falls on the internal DNS server configuration (192.168.112.2). The record for `internal.example.com` appears missing, incorrect, or otherwise unavailable.

