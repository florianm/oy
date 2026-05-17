# oy-cli audits and more

AI harness for code audits and more

## Conduct an automated security audit

To conduct an automated security audit of a given repository:

- Create a Codespace at `florianm/oy`.
- Run `oy doctor` to diagnose the correct installation of `oy-cli`
- Connect `oy-cli` with the provider of your choice, e.g.
  `oy model copilot::gpt-5.4`.
- Download and unpack the target repository `<REPO>` into the `/src` folder and
  conduct a security audit:

  ```
  cd src
  unzip src/<REPO>.zip
  cd REPO
  oy audit "security and compliance" --out <YYYY-MM-DD>_ISSUES_<REPO>.md
  oy audit "security and compliance" --format sarif --out <YYYY-MM-DD>_ISSUES_<REPO>.sarif
  ```

- Move the outputs into `/findings` and delete the contents of `/src`.
- To publish sarif to GitHub so that findings appear in the Security tab 
  you need a fine-grained PAT with write permissions for the target repo.
  

### References

- [oy-cli rust crate](https://crates.io/crates/oy-cli)
- [oy-cli docs](https://docs.rs/oy-cli/0.7.15/oy/)
