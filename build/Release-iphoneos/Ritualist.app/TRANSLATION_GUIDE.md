# Translation Guide for Ritualist

This guide provides context and instructions for translating the Ritualist habit tracking app.

## About Ritualist

Ritualist is a habit tracking application that helps users build and maintain positive daily routines. Users can create habits, track their completion on a calendar, and view their progress streaks.

## Key Concepts

### Habits
- **Binary Habits**: Yes/No tracking (e.g., "Did you meditate today?")
- **Numeric Habits**: Value-based tracking (e.g., "How many glasses of water?")
- **Streaks**: Consecutive days of habit completion

### User Interface Areas
- **Overview**: Main calendar view for tracking habits
- **Habits**: List view for managing habits
- **Settings**: User preferences and configuration

## Translation Guidelines

### 1. Length Constraints

**Tab Bar Labels** (navigation.*)
- Maximum 12 characters recommended
- Should be single words when possible
- Examples: "Overview", "Habits", "Settings"

**Button Labels** (button.*)
- Keep concise and action-oriented
- Maximum 15 characters recommended
- Examples: "Save", "Cancel", "Delete"

**Form Field Labels** (form.*)
- Can be longer for clarity
- Should fit comfortably in form layouts
- Examples: "Basic Information", "Daily Target"

**Validation Messages** (validation.*)
- Should be clear and helpful
- Maximum 80 characters recommended
- Explain what the user needs to do

### 2. Tone and Style

- **Encouraging**: Use positive language that motivates users
- **Clear**: Avoid ambiguous or technical terms
- **Consistent**: Use the same terminology throughout the app
- **Respectful**: Consider cultural sensitivity

### 3. Special String Types

#### Pluralization Strings
- Use proper plural rules for your language
- Format: `%lld` for number replacement
- Example: "1 day" vs "5 days"

#### String Interpolation
- `%@` is replaced with text (names, dates)
- `%lld` is replaced with numbers
- Maintain the order that makes sense in your language

#### Accessibility Labels
- Written for screen readers (VoiceOver)
- Should sound natural when read aloud
- Include context about the action or state
- Example: "Tap to log habit for January 15th"

### 4. Cultural Considerations

#### Date and Time
- The app automatically handles date formatting
- Week start day respects user preferences
- Consider local calendar conventions

#### Numbers
- The app handles locale-specific number formatting
- Decimal separators and grouping are automatic
- Focus on translating unit labels (cups, minutes, etc.)

### 5. Context-Specific Translations

#### Habit Types
- **Binary habits**: Yes/No, completed/not completed
- **Numeric habits**: Require units like "cups of water", "minutes of exercise"

#### Streak Terminology
- "Current streak": Ongoing consecutive days
- "Best streak": Highest achievement ever
- Should motivate continued progress

#### Error Messages
- Be specific about what went wrong
- Provide clear next steps
- Maintain helpful tone even for errors

## Testing Your Translation

### UI Layout
- Test with longer text to ensure it fits
- Check that buttons remain readable
- Verify form layouts don't break

### Accessibility
- Test with screen reader if possible
- Ensure labels make sense when read aloud
- Check that dynamic content (dates, numbers) flows naturally

### Cultural Fit
- Verify terminology matches local habits around wellness/productivity
- Check that tone aligns with cultural communication styles
- Ensure examples (units, activities) are relevant locally

## Common Translation Challenges

### 1. Habit vs. Routine vs. Practice
Choose the term that best resonates in your culture for positive daily activities.

### 2. Streak vs. Chain vs. Series
Select terminology that conveys consecutive progress and motivation.

### 3. Log vs. Track vs. Record
Use the most natural verb for marking habit completion.

### 4. Target vs. Goal vs. Objective
Choose terms that feel achievable and positive, not intimidating.

## String Categories Reference

```
app.*          - Application name and branding
navigation.*   - Tab bar and screen titles
button.*       - Action buttons throughout the app
loading.*      - Progress indicators and wait states
status.*       - Current state descriptions
error.*        - Error messages and failures
empty.*        - Empty state descriptions
form.*         - Form labels and field names
validation.*   - Input validation messages
settings.*     - User preference options
day.*          - Day names and abbreviations
overview.*     - Calendar and statistics displays
dialog.*       - Confirmation and alert messages
accessibility.* - Screen reader labels
format.*       - Number and date formatting
test.*         - Development and testing strings
```

## Questions?

If you need clarification about any string's context or usage, please refer to the comment fields in the String Catalog or contact the development team.

Remember: Your translation helps users build better habits and improve their lives. Focus on creating an experience that feels natural and motivating in your language and culture.