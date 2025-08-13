# Anti-Patterns (40 tokens)

**NEVER:**
- Use Combine (user explicitly rejected)
- Premature refactoring without clear bugs or improvement goals
- Direct service calls from ViewModels (use UseCases)
- Repository calls from Views (use UseCases → Repositories)
- MainActor.run in @MainActor classes
- Break working functionality for theoretical improvements