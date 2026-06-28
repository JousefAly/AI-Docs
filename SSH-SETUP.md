# GitHub SSH Setup (Windows)

For pushing to a personal GitHub account from a machine already using a work git identity.

---

## 1. Generate an SSH key

```powershell
ssh-keygen -t ed25519 -C "your@email.com" -f "$env:USERPROFILE\.ssh\id_ed25519_github_personal" -N '""'
```

No passphrase (`-N '""'`) so git never prompts.

---

## 2. Create SSH config

Create or edit `C:\Users\<you>\.ssh\config`:

```
Host github-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github_personal
    IdentitiesOnly yes
```

The `Host` alias (`github-personal`) lets you have multiple GitHub identities on the same machine without them colliding.

---

## 3. Add the public key to GitHub

Copy the public key:

```powershell
Get-Content "$env:USERPROFILE\.ssh\id_ed25519_github_personal.pub"
```

Then go to **GitHub → Settings → SSH and GPG keys → New SSH key**, paste it, save.

---

## 4. Set the repo's remote to use the SSH alias

```powershell
git remote set-url origin "git@github-personal:YourUsername/your-repo.git"
```

Also set the local git identity for this repo so commits show the right author:

```powershell
git config user.email "your@email.com"
git config user.name "YourName"
```

---

## 5. Test and push

```powershell
ssh -T git@github-personal
# Expected: Hi YourUsername! You've successfully authenticated...

git push origin master
```

---

## Notes

- The `ssh-agent` Windows service is often disabled. It's not needed as long as the key has no passphrase.
- Each new repo on this account just needs step 4 — the key and config are reused.
- On a new machine, repeat all 5 steps. The private key (`id_ed25519_github_personal`) does **not** go in this repo — generate a fresh one per machine.
