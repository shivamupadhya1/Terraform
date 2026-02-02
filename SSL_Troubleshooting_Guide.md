Markdown
# 📖 Troubleshooting Guide: Jenkins to JBoss SSL Handshake Failure

## 1. Issue Overview
* **Symptom:** Jenkins deployments to JBoss fail with the error: `WFLYPRT0053: Could not connect to remote+https://...` followed by `PKIX path building failed`.
* **Root Cause:** The Jenkins Java environment (Truststore) does not recognize the **Intermediate Certificate Authority (CA)** that signed the JBoss SSL certificate.
* **Trigger:** This typically occurs after a Java version update on the Jenkins Controller or Node Agent, which resets the default `cacerts` file.

---

## 2. Technical Context: The "Chain of Trust"
An SSL certificate is not just a single file; it is a chain of trust. For a connection to be trusted, the client (Jenkins) must verify a path from the server certificate back to a **Root CA** it already trusts.

* **JBoss Side:** In this environment, the `newgen.p12` file contains a **Chain Length of 1** (identity certificate only). It does not "send" the intermediate link during the handshake.
* **Jenkins Side:** Because JBoss does not send the link, Jenkins must manually have the **Intermediate CA** (`GlobalSign RSA OV SSL CA 2018`) in its local `cacerts` file to complete the chain.



---

## 3. Resolution Steps

### Step 1: Identify the Active Java Home
Run this command on the affected Jenkins machine (Controller or Agent) to find the Java path being used:
```bash
readlink -f $(which java)
Example Path: /usr/lib/jvm/java-17-openjdk-17.0.14.0.7-2.el9.x86_64/bin/java

Step 2: Obtain the Intermediate Certificate
Download the specific certificate that matches the "Issuer" found in the logs:

Bash
wget [https://secure.globalsign.com/cacert/gsrsaovsslca2018.crt](https://secure.globalsign.com/cacert/gsrsaovsslca2018.crt)
Step 3: Import into Java Truststore
Use the keytool utility to add the certificate to the Java cacerts file.

Note: The default password for the Java keystore is changeit.

Bash
# Example command (adjust path based on Step 1)
sudo keytool -import -trustcacerts -alias globalsign_intermediate_2018 \
-file gsrsaovsslca2018.crt \
-keystore /usr/lib/jvm/java-17-openjdk-17.0.14.0.7-2.el9.x86_64/lib/security/cacerts
Step 4: Verify the Import
Confirm the certificate is present in the truststore:

Bash
keytool -list -keystore [PATH_TO_CACERTS] -alias globalsign_intermediate_2018
Step 5: Refresh the Jenkins Connection
For Controller: Restart the Jenkins service (sudo systemctl restart jenkins).

For Agents: Disconnect and Reconnect the node from the Jenkins "Manage Nodes" UI to restart the Java process with the updated truststore.

4. Maintenance & Prevention
Java Updates: On RHEL/Linux, a dnf update that installs a new Java version (e.g., 17.0.14 to 17.0.16) creates a new directory and a fresh cacerts file. You must re-run the import for the new version.

System-Wide Trust (Recommended): To make this "update-proof" on RHEL 9, add the .crt file to the system trust anchors:

Bash
sudo cp gsrsaovsslca2018.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
OpenJDK is usually configured to pull from this system-wide store automatically.