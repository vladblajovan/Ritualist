# ML-Powered Personalized Messages Specification

## 📋 Overview

Transform generic motivational messages into personality-aware, context-sensitive encouragement that resonates with each user's psychological profile and current situation.

**Status**: Specification Phase
**Priority**: High - Significant UX improvement
**Estimated Effort**: 2-3 days
**Dependencies**: Personality Analysis System (completed)

---

## 🎯 Goals

### Primary Objectives
1. **Personality Alignment**: Messages match user's Big Five personality traits
2. **Context Awareness**: Consider completion rate, time of day, streak status, struggles
3. **Natural Language**: ML-powered phrase selection feels human, not templated
4. **Emotional Resonance**: Right tone for right person at right moment

### Success Metrics
- Messages feel "personal" rather than generic
- Users perceive app as "understanding them"
- Increased engagement with inspiration cards
- Positive user feedback on messaging tone

---

## 🏗️ Architecture

### Component Structure

```
PersonalizedMessageGenerator (Service)
├── Input: MessageContext
│   ├── trigger: InspirationTrigger
│   ├── personality: PersonalityProfile
│   ├── completionRate: Double
│   ├── streakInfo: StreakInfo?
│   ├── timeOfDay: TimeOfDay
│   ├── userName: String?
│   └── recentPatterns: BehaviorPatterns
│
├── ML Processing Layer
│   ├── Personality Tone Analyzer
│   ├── Context-Aware Template Selector
│   ├── Semantic Phrase Generator (NLEmbedding)
│   └── Emoji & Punctuation Adjuster
│
└── Output: PersonalizedMessage
    ├── content: String
    ├── tone: MessageTone
    └── confidence: Double
```

### Data Flow

```
1. Overview triggers inspiration
   ↓
2. OverviewViewModel collects context
   (personality profile, completion, time, patterns)
   ↓
3. PersonalizedMessageGenerator analyzes context
   - Match trigger to message template category
   - Load personality profile
   - Analyze recent behavior patterns
   ↓
4. ML Processing
   - Select personality-appropriate base template
   - Generate semantic variations using NLEmbedding
   - Adjust tone based on context
   - Select appropriate emoji
   ↓
5. Return personalized message
   ↓
6. Display in InspirationCard
```

---

## 🧠 Personality-Based Messaging Strategy

### Openness to Experience (Explorer)
**Core Values**: Curiosity, creativity, variety, growth, possibility

**Messaging Approach**:
- Emphasize discovery and exploration
- Use metaphors and vivid language
- Celebrate variety in habit choices
- Encourage experimentation
- Frame progress as learning journey

**Tone**: Enthusiastic, imaginative, inspiring
**Keywords**: discover, explore, possibilities, creative, growth, adventure, unique
**Emoji Style**: Diverse, expressive (🌟✨🚀🎨🔭)

**Examples**:
- Generic: "Good morning! Ready to start your day?"
- Personalized: "Good morning! What new possibilities will today bring? 🌟"

- Generic: "Halfway there!"
- Personalized: "You're discovering your rhythm! Halfway through with 3 unique habits completed. 🎨"

---

### Conscientiousness (Achiever)
**Core Values**: Structure, achievement, discipline, goals, consistency

**Messaging Approach**:
- Emphasize metrics and progress
- Use achievement language
- Celebrate consistency and discipline
- Reference goals and targets
- Frame progress as measurable success

**Tone**: Focused, disciplined, achievement-oriented
**Keywords**: achieve, complete, systematic, precise, goals, consistency, excellence
**Emoji Style**: Achievement-focused (🎯✅📊🏆⚡)

**Examples**:
- Generic: "Good morning! Ready to start your day?"
- Personalized: "Good morning! Time to execute your daily plan with precision. 🎯"

- Generic: "Halfway there!"
- Personalized: "Excellent progress! 50% completion rate achieved. On track for daily goal. ✅"

---

### Extraversion (Connector)
**Core Values**: Energy, social connection, enthusiasm, interaction

**Messaging Approach**:
- Emphasize energy and momentum
- Use enthusiastic, energetic language
- Celebrate social habits
- Reference community and connection
- Frame progress as shared experience

**Tone**: Energetic, enthusiastic, social
**Keywords**: energy, momentum, together, community, shine, powerful, vibrant
**Emoji Style**: High-energy, celebratory (⚡🔥💪🎉🌟)

**Examples**:
- Generic: "Good morning! Ready to start your day?"
- Personalized: "Good morning! Let's bring the energy today! You've got this! ⚡"

- Generic: "Halfway there!"
- Personalized: "You're on fire! Halfway through and the momentum is incredible! 🔥"

---

### Agreeableness (Caregiver)
**Core Values**: Compassion, helping, relationships, harmony, kindness

**Messaging Approach**:
- Emphasize care and support
- Use warm, compassionate language
- Celebrate caring habits
- Reference relationships and impact
- Frame progress as positive contribution

**Tone**: Warm, supportive, compassionate
**Keywords**: care, support, kindness, together, nurture, harmony, positive impact
**Emoji Style**: Warm, caring (💝🤗🌸💚🌼)

**Examples**:
- Generic: "Good morning! Ready to start your day?"
- Personalized: "Good morning! Ready to make a positive difference today? 💝"

- Generic: "Halfway there!"
- Personalized: "Beautiful progress! Your caring actions are making a real difference. 🌸"

---

### Neuroticism (Struggler)
**Core Values**: Coping, stability, progress, self-compassion, resilience

**Messaging Approach**:
- Emphasize progress over perfection
- Use calming, reassuring language
- Celebrate small wins
- Acknowledge difficulty
- Frame progress as resilience

**Tone**: Reassuring, patient, encouraging
**Keywords**: progress, step by step, resilience, every effort counts, you're doing well
**Emoji Style**: Gentle, encouraging (💪🌱✨🫂💙)

**Examples**:
- Generic: "Good morning! Ready to start your day?"
- Personalized: "Good morning! One step at a time—you've got this. 🌱"

- Generic: "Halfway there!"
- Personalized: "You're doing great! Halfway through—every step forward counts. 💪"

---

## 🔄 Context-Aware Adaptations

### Completion Rate Adjustments

**High Completion (>80%)**:
- Openness: Celebrate exploration and variety
- Conscientiousness: Recognize systematic excellence
- Extraversion: Amplify energy and momentum
- Agreeableness: Acknowledge positive impact
- Neuroticism: Build confidence, celebrate stability

**Medium Completion (50-80%)**:
- All: Encouraging, recognizing steady progress

**Low Completion (<50%)**:
- Openness: Reframe as learning experience
- Conscientiousness: Encourage reset and planning
- Extraversion: Re-energize with possibility
- Agreeableness: Self-compassion messaging
- Neuroticism: Extra gentle, focus on any progress

### Time of Day Adaptations

**Morning**:
- Openness: What will you discover?
- Conscientiousness: Execute the plan
- Extraversion: Bring the energy
- Agreeableness: Make a difference
- Neuroticism: One step at a time

**Midday**:
- All: Maintain momentum, acknowledge effort

**Evening**:
- All: Reflect on progress, prepare for tomorrow

### Streak-Based Adjustments

**Strong Streak (7+ days)**:
- Add streak acknowledgment
- Reinforce consistency
- Celebrate momentum

**Broken Streak**:
- Reframe as comeback opportunity
- Focus on today, not yesterday
- Emphasize resilience

---

## 🤖 ML Implementation Strategy

### Level 1: Template-Based (Phase 1)
**Approach**: Pre-written personality variants for each trigger
**ML Usage**: Minimal - personality classification only
**Complexity**: Low
**Quality**: Good - predictable, proven phrases

```swift
let templates = [
    .halfwayPoint: [
        .openness: ["You're discovering your rhythm!", "Love your consistency!"],
        .conscientiousness: ["Excellent progress!", "50% completion achieved"],
        // ... etc
    ]
]
```

### Level 2: Semantic Phrase Selection (Phase 2)
**Approach**: Multiple template options, ML selects best fit using context
**ML Usage**: NLEmbedding to match phrases to user context
**Complexity**: Medium
**Quality**: Very Good - context-aware selection

```swift
// Analyze user's recent habit names using embeddings
let userContext = analyzeRecentHabits(using: embedding)

// Select phrases that semantically match user's focus areas
let selectedPhrases = selectBestMatch(
    from: templateVariants,
    matching: userContext,
    personality: dominantTrait
)
```

### Level 3: Generative (Phase 3 - Future)
**Approach**: Use on-device LLM to generate novel messages
**ML Usage**: Apple MLX or similar on-device generation
**Complexity**: High
**Quality**: Excellent - fully personalized

*Note: Phase 3 requires iOS 18+ and more research*

---

## 📊 Message Template Structure

### Template Categories (11 Total)

1. **Session Start** - User opens app
2. **Morning Motivation** - First check-in of the day
3. **First Habit Complete** - Momentum builder
4. **Halfway Point** - Mid-progress encouragement
5. **Struggling Mid-Day** - Support during difficulty
6. **Afternoon Push** - Re-energize
7. **Strong Finish** - Near completion encouragement
8. **Perfect Day** - All habits complete
9. **Evening Reflection** - End of day
10. **Weekend Motivation** - Weekend-specific
11. **Comeback Story** - After missed days

### Template Structure

```swift
struct MessageTemplate {
    let trigger: InspirationTrigger
    let variants: [PersonalityTrait: [MessageVariant]]
}

struct MessageVariant {
    let baseMessage: String
    let tone: MessageTone
    let contextAdaptations: [CompletionRange: String]
    let emojiOptions: [String]
    let keywords: [String] // For semantic matching
}

enum MessageTone {
    case enthusiastic
    case focused
    case energetic
    case warm
    case gentle
}
```

---

## 🔧 Technical Implementation

### Service Interface

```swift
public protocol PersonalizedMessageGeneratorProtocol {
    /// Generate personalized message based on context
    func generateMessage(for context: MessageContext) async -> PersonalizedMessage

    /// Check if ML-enhanced generation is available
    var isMLAvailable: Bool { get }
}

public struct MessageContext {
    let trigger: InspirationTrigger
    let personality: PersonalityProfile?
    let completionPercentage: Double
    let timeOfDay: TimeOfDay
    let userName: String?
    let currentStreak: Int
    let recentPattern: CompletionPattern
}

public struct PersonalizedMessage {
    let content: String
    let tone: MessageTone
    let generationMethod: GenerationMethod // template, semantic, generated
}

public enum GenerationMethod {
    case template           // Pre-written variant selected
    case semanticML         // ML-enhanced phrase selection
    case generated          // Future: LLM-generated
}
```

### Integration Points

**1. OverviewViewModel**
```swift
@Injected(\.personalizedMessageGenerator)
private var messageGenerator

private func getPersonalizedMessage(for trigger: InspirationTrigger) async -> String {
    let context = MessageContext(
        trigger: trigger,
        personality: await loadPersonalityProfile(),
        completionPercentage: todaysSummary?.completionPercentage ?? 0.0,
        timeOfDay: currentTimeOfDay,
        userName: await getUserName(),
        currentStreak: todaysSummary?.currentStreak ?? 0,
        recentPattern: analyzeRecentPattern()
    )

    let message = await messageGenerator.generateMessage(for: context)
    return message.content
}
```

**2. UseCase Layer**
```swift
public final class GeneratePersonalizedMessage: GeneratePersonalizedMessageUseCase {
    private let messageGenerator: PersonalizedMessageGeneratorProtocol
    private let personalityRepo: PersonalityAnalysisRepositoryProtocol

    public func execute(for context: MessageContext) async -> PersonalizedMessage {
        await messageGenerator.generateMessage(for: context)
    }
}
```

---

## 📝 Implementation Phases

### Phase 1: Foundation (Current Sprint)
**Goal**: Template-based personality variants

**Tasks**:
1. Create `PersonalizedMessageGenerator` service
2. Define message template structure
3. Write personality-specific variants for all 11 triggers
4. Integrate with OverviewViewModel
5. Add personality profile loading to message generation
6. Update InspirationCard to handle new messages

**Deliverable**: Working personality-aware messages using template selection

**Testing**:
- Populate each personality profile scenario
- Verify appropriate messages display
- Confirm tone matches personality
- Check all 11 triggers work

---

### Phase 2: ML Semantic Enhancement (Next Sprint)
**Goal**: Context-aware phrase selection using NLEmbedding

**Tasks**:
1. Add semantic analysis of user's recent habits
2. Generate "user context vector" from habit names
3. Pre-compute phrase embeddings for all variants
4. Select phrases with highest semantic similarity
5. Blend personality + semantic context

**Deliverable**: ML-enhanced messages that reference user's actual focus areas

**Example**:
- User has learning habits → "Keep growing your knowledge!"
- User has fitness habits → "Keep building your strength!"
- User has social habits → "Keep connecting and shining!"

---

### Phase 3: Advanced ML (Future)
**Goal**: Generative on-device messages

**Tasks**:
1. Research on-device LLM options (Apple MLX, etc.)
2. Fine-tune model on personality-appropriate language
3. Implement generation with safety guardrails
4. A/B test generated vs template messages

**Deliverable**: Fully generated, novel messages

---

## 📐 Example Message Matrix

### Halfway Point Trigger

| Personality | Low Completion (<50%) | Medium (50-80%) | High (>80%) |
|-------------|----------------------|-----------------|-------------|
| **Openness** | "Every habit is a learning experience! You're on your journey. 🌱" | "You're discovering your rhythm! Halfway through with steady progress. 🎨" | "Love your consistency across diverse habits! Halfway and exploring brilliantly! ✨" |
| **Conscientiousness** | "Time to regroup and refocus. A strong plan leads to strong results. 📋" | "Systematic progress! 50% completion rate maintained. On track. ✅" | "Exceptional execution! 50% milestone achieved with precision. Excellence! 🎯" |
| **Extraversion** | "Don't lose the energy! Every habit brings momentum. Let's go! ⚡" | "You're building momentum! Halfway through with solid energy! 🔥" | "You're on fire! Halfway mark and the energy is incredible! Unstoppable! 💪" |
| **Agreeableness** | "You're doing your best, and that matters. Keep caring for yourself. 💙" | "Beautiful progress! Your caring actions are creating positive change. 🌸" | "Your dedication to caring habits is inspiring! Halfway with grace! 💝" |
| **Neuroticism** | "You're doing great! Every step forward counts, truly. 🌱" | "You're making real progress! Halfway there—one step at a time. 💪" | "Look at you go! Halfway through with solid consistency. Proud of you! ✨" |

---

## 🎨 Emoji Selection Strategy

### Per-Personality Emoji Palettes

**Openness**: 🌟✨🎨🔭🚀🌈🎭📚🗺️💡🌸🦋
*Visual, diverse, creative*

**Conscientiousness**: 🎯✅📊🏆⚡📋✔️🎖️💼📈⏰
*Achievement, structure, completion*

**Extraversion**: ⚡🔥💪🎉🌟🚀💥✨🙌😄🎊
*Energy, celebration, power*

**Agreeableness**: 💝🤗🌸💚🌼🫂💙🌻☀️🌺🕊️
*Warmth, care, gentleness*

**Neuroticism**: 💪🌱✨🫂💙🌿💚🧘🌤️🕊️☮️
*Gentle, growth, calm*

### Context-Based Emoji Rules

1. **Morning**: Sunrise, coffee, fresh starts (🌅☀️☕🌄)
2. **Midday**: Energy, momentum (⚡🔥💪)
3. **Evening**: Reflection, calm, completion (🌙✨🏆)
4. **Perfect Day**: Celebration (🎉🎊🏆🌟)
5. **Struggling**: Support, gentle encouragement (💪🌱💙)

---

## 🧪 Testing Strategy

### Unit Tests
- Template selection logic
- Personality mapping accuracy
- Context adaptation correctness
- Emoji selection rules

### Integration Tests
- Full message generation pipeline
- Personality profile loading
- UseCase integration
- ViewModel integration

### User Testing
- Each personality profile scenario
- All 11 trigger types
- Various completion rates
- Different times of day
- User feedback surveys

### Success Criteria
- ✅ Messages match personality descriptions
- ✅ Tone feels natural, not robotic
- ✅ Context adaptations work correctly
- ✅ Users perceive messages as "personal"
- ✅ No offensive or inappropriate content

---

## 🚀 Rollout Plan

### Phase 1: Silent Launch
- Deploy to internal testing
- Populate all 5 personality profiles
- Verify message quality
- Gather team feedback

### Phase 2: TestFlight Beta
- Enable for TestFlight users
- Monitor crash reports
- Collect user feedback
- A/B test against generic messages

### Phase 3: Production Rollout
- Gradual rollout (20% → 50% → 100%)
- Monitor engagement metrics
- Track user satisfaction
- Iterate based on feedback

---

## 📊 Success Metrics

### Quantitative
- **Engagement Rate**: % of users who interact with inspiration card
- **Dismissal Time**: Average time before dismissing card (longer = more engaging)
- **Return Rate**: % of users who return after seeing personalized messages
- **Completion Rate**: Impact on daily habit completion rates

### Qualitative
- User feedback: "Messages feel personal"
- Support tickets: Sentiment about messaging
- App Store reviews: Mentions of motivation/encouragement
- User interviews: Perceived understanding

---

## 🔮 Future Enhancements

### Advanced Context
- Weather-aware messages ("Sunny day—perfect for your outdoor habits!")
- Location-aware ("Coffee shop vibes—great for your reading habit!")
- Habit-specific encouragement ("Your meditation streak is inspiring!")

### Multi-Modal
- Voice-based messages (accessibility)
- Rich media (images, animations)
- Interactive messages (polls, choices)

### Social Integration
- Community achievements
- Friend comparisons (opt-in)
- Shared milestones

---

## 📚 References

### Personality Psychology
- Big Five trait descriptions
- Motivational interviewing techniques
- Positive psychology principles

### ML/NLP Resources
- Apple NLEmbedding documentation
- Semantic similarity algorithms
- On-device ML best practices

### UX Writing
- Conversational UI principles
- Tone of voice guidelines
- Emoji usage research

---

## ✅ Definition of Done

**Phase 1 Complete When**:
- [ ] PersonalizedMessageGenerator service implemented
- [ ] All 11 trigger types have personality variants (55 base templates)
- [ ] Integration with OverviewViewModel complete
- [ ] All 5 personality profiles tested
- [ ] User testing shows clear preference for personalized vs generic
- [ ] Zero crashes or errors in message generation
- [ ] Code reviewed and approved
- [ ] Documentation updated

**Phase 2 Complete When**:
- [ ] Semantic analysis integration working
- [ ] Context-aware phrase selection functional
- [ ] ML availability check implemented
- [ ] A/B testing shows improvement over Phase 1
- [ ] Performance impact acceptable (<50ms generation time)

---

**Document Version**: 1.0
**Last Updated**: 2025-10-31
**Author**: AI Development Team
**Status**: Ready for Implementation
