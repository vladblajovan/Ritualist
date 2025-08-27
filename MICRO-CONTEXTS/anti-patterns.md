# Anti-Patterns (60 tokens)

**NEVER:**
- Use Combine (user explicitly rejected)
- Mock-based testing (project-analysis.md critical issue)
- Premature refactoring without clear bugs or improvement goals
- Direct service calls from ViewModels (use UseCases)
- Repository calls from Views (use UseCases → Repositories)
- MainActor.run in @MainActor classes
- Break working functionality for theoretical improvements
- Repeated build attempts for debugging (analyze code structure first)