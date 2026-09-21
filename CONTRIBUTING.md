# Contributing to KitoKeychain

Thanks for considering a contribution — Kito is open source and welcomes
issues and pull requests from anyone.

## Governance

- **Anyone can open an issue or a pull request.**
- **Only the maintainer ([wyksoftsinc.com](https://wyksoftsinc.com), repo
  owner Wycliff) merges pull requests.**
- Every PR is verified before merge: it must build, its tests must pass, and
  it must follow the engineering standards linked below.

## Workflow

1. Fork the repo. Open an issue first for anything beyond a trivial fix.
2. Create a branch off `main`.
3. Follow [KitoCore's engineering standards](https://github.com/WykSofts-Inc/KitoCore/blob/main/docs/ENGINEERING_STANDARDS.md).
4. Add or update tests. Run `swift test` locally.
5. Update the README if you changed or added public API.
6. Open a pull request against `main` — please don't merge your own PR.

## Code review checklist

- [ ] Builds cleanly (`swift build`)
- [ ] Tests pass (`swift test`), and new behavior has new tests
- [ ] No `fatalError()`, `try!`, or unexplained force-unwrap in public code
- [ ] Public API changes are documented in the README with a sample

## Code of conduct

Be respectful. Disagreement about a technical approach is fine and expected.

## License

By contributing, you agree your contribution is licensed under this repo's
[MIT License](LICENSE).
