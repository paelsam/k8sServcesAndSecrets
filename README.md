# 🗝️ Kubernetes Treasure Hunt Lab

In this lab, each group will create a **Treasure Hunt application** where every member contributes a clue.  
At the end, all clues will be combined to form a complete secret phrase.

---

## 1. How the container works

The frontend application loads its configuration from a `config.js` file, which is dynamically generated using environment variables.

The template looks like this:

```javascript
window.CONFIG = {
  title: "${TITLE}",
  student: "${STUDENT}",
  salt: "${SALT}",
  keyHash: "${KEY_HASH}",
  clue: ${CLUE_JSON}
};
```

- **TITLE** → Title of the page (e.g., `Treasure Hunt — Ana`)
- **STUDENT** → Student name or identifier
- **SALT** → A string that, combined with the key, produces a hash
- **KEY_HASH** → The SHA-256 hash of `SALT + KEY`
- **CLUE** → The actual clue to reveal (passed first as an environment variable, later from a Kubernetes Secret)

---

## 2. Generating SALT and KEY_HASH

Each student must create their own **SALT** and **KEY**.  
The **KEY** is the secret that will be typed into the frontend to unlock the clue.

### Example (Linux / macOS)

```bash
SALT="DS3univalle"
KEY="papitas123"

# Generate SHA-256(SALT + KEY)
printf "%s" "${SALT}${KEY}" | sha256sum | awk '{print $1}'
```

### Example (macOS alternative)

```bash
printf "%s" "DS3univallepapitas123" | shasum -a 256 | awk '{print $1}'
```

### Example (Windows PowerShell)

```powershell
$SALT = "DS3univalle"
$KEY  = "papitas123"
$bytes = [Text.Encoding]::UTF8.GetBytes("$SALT$KEY")
$hash  = [Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
($hash | ForEach-Object { $_.ToString("x2") }) -join ""
```

Use this **hash value** as `KEY_HASH`.

---

## 3. First tests with Docker

Build the container locally:

```bash
docker build -t treasure-new:latest .
```

Run with environment variables:

```bash
docker run --rm -p 8080:80   -e TITLE="Treasure Hunt — Ana"   -e STUDENT="ana"   -e SALT="DS3univalle"   -e KEY_HASH="PUT_YOUR_GENERATED_HASH_HERE"   -e CLUE=$'CLUE-A: "DEPLOYMENT"\nTip: Team up and combine all clues.'   treasure-new:latest
```

Open [http://localhost:8080](http://localhost:8080) and test your clue.

---

## 4. Publishing the image

You must publish the image so it can be pulled by Kubernetes.  
Two common registries are **Docker Hub** and **GitHub Container Registry (GHCR)**.

### Option A: Docker Hub
1. Log in:
   ```bash
   docker login -u YOUR_DOCKERHUB_USERNAME
   ```
2. Tag the image:
   ```bash
   docker tag treasure-new:latest YOUR_DOCKERHUB_USERNAME/treasure-new:latest
   ```
3. Push it:
   ```bash
   docker push YOUR_DOCKERHUB_USERNAME/treasure-new:latest
   ```

### Option B: GitHub Container Registry (GHCR)
1. Create a Personal Access Token (PAT) with `write:packages`.
2. Log in:
   ```bash
   docker login ghcr.io -u fredyunivalle
   # paste your PAT when asked
   ```
3. Tag the image:
   ```bash
   docker tag treasure-new:latest ghcr.io/fredyunivalle/treasure-new:latest
   ```
4. Push it:
   ```bash
   docker push ghcr.io/fredyunivalle/treasure-new:latest
   ```
5. Make sure the package is set to **public** in GitHub → Packages → Settings.

---

## 5. Kubernetes: create the namespace

```bash
kubectl create namespace treasure-hunt
```

---

## 6. Kubernetes: Secrets

Clues must not be hardcoded. We store them in Kubernetes Secrets.  
Secrets use **base64 encoding**, which is why you see a "weird string".

Example:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ana-clue
  namespace: treasure-hunt
type: Opaque
data:
  CLUE: Q0xVRS1BOiAiUEFQSVRBUyJcbg==
```

👉 `Q0xVRS1BOiAiUEFQSVRBUyJcbg==` is the base64 encoding of the string:

```
CLUE-A: "PAPITAS"
```

Generate base64 easily:

```bash
echo -n 'CLUE-A: "PAPITAS"' | base64
```

---

## 7. Kubernetes: Deployment + Service

Create a deployment that mounts the secret and passes the values as environment variables:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: treasure-ana
  namespace: treasure-hunt
spec:
  replicas: 1
  selector:
    matchLabels:
      app: treasure-ana
  template:
    metadata:
      labels:
        app: treasure-ana
    spec:
      containers:
        - name: web
          image: ghcr.io/fredyunivalle/treasure-new:latest
          ports:
            - containerPort: 80
          env:
            - name: TITLE
              value: "Treasure Hunt — Fredy"
            - name: STUDENT
              value: "Fredy"
            - name: SALT
              value: "DS3univalle"
            - name: KEY_HASH
              value: "e03071406de634efb44ae42fb52a19523ac5646281b91de291133e2c37106da0"
            - name: CLUE
              valueFrom:
                secretKeyRef:
                  name: ana-clue
                  key: CLUE
---
apiVersion: v1
kind: Service
metadata:
  name: treasure-ana
  namespace: treasure-hunt
spec:
  selector:
    app: treasure-ana
  ports:
    - name: http
      port: 80
      targetPort: 80
  type: NodePort
```

---

## 8. Testing in Kubernetes

Forward the service port to your local machine:

```bash
kubectl -n treasure-hunt port-forward svc/treasure-ana 8080:80
```

Open [http://localhost:8080](http://localhost:8080).

If everything is correct, you can type your KEY and reveal the clue.

---

## 🎯 Final Objective

- Each student (or each pod) has a different **clue**.  
- Each group must combine their clues to reconstruct the **full secret phrase**.  
- This exercise teaches:
  - How to build and publish Docker images  
  - How to generate secure hashes (SALT + KEY)  
  - How to use Kubernetes Secrets  
  - How to deploy Pods and Services  
  - How to test applications with `kubectl port-forward`

Good luck, and have fun unlocking the treasure! 🏴‍☠️