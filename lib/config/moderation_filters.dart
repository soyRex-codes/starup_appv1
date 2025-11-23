/// Local moderation filters - first layer of content screening
/// Checks content against inappropriate words/patterns before calling expensive AI APIs
/// This saves costs and improves response time by catching obvious violations early
library;

/// Severity levels for moderation decisions
enum ModerationSeverity {
  high, // Instant block
  medium, // Flag for manual review or block based on count
  low, // Monitor/log only
}

class ModerationFilters {
  /// Categories of inappropriate content with severity levels
  /// Severity: HIGH = instant block, MEDIUM = flag for manual review, LOW = monitor

  // ============================================================================
  // SEXUAL/EXPLICIT CONTENT - HIGH SEVERITY (instant block)
  // ============================================================================
  static const List<String> sexualExplicit = [
    // Explicit acts
    'porn', 'porno', 'pornography', 'xxx', 'nsfw',
    'sex tape', 'sextape', 'nude pic', 'nudes', 'send nudes',
    'dick pic', 'pussy pic', 'boob pic', 'ass pic',

    // Solicitation
    'hook up', 'hookup', 'one night stand', 'fuck buddy',
    'fwb', 'friends with benefits',
    'sugar daddy', 'sugar baby', 'escort', 'prostitute',

    // Extreme sexual terms (avoiding detailed anatomical terms)
    'anal sex', 'oral sex', 'blowjob', 'handjob', 'gangbang',
    'cumshot', 'creampie', 'facial', 'deepthroat',

    // Adult services
    'onlyfans promotion', 'buy my nudes', 'premium snapchat',
    'cam girl', 'camgirl', 'webcam show',
  ];

  // ============================================================================
  // HATE SPEECH & SLURS - HIGH SEVERITY (instant block)
  // ============================================================================
  static const List<String> hateSpeech = [
    // Racial slurs (using asterisks for safety)
    'n*gger', 'n*gga', 'ch*nk', 'sp*c', 'k*ke',
    'sand n*gger', 'towelhead', 'camel jockey',

    // Homophobic slurs
    'f*ggot', 'f*g', 'dyke', 'tr*nny', 'sh*male',

    // Dehumanizing terms
    'subhuman', 'vermin', 'cockroach', 'parasite',
    'infestation', 'plague',

    // Nazi/extremist
    'heil hitler', 'hitler was right', 'white power',
    'kill all', 'genocide', 'ethnic cleansing',
    '1488', 'blood and soil',
  ];

  // ============================================================================
  // THREATS & VIOLENCE - HIGH SEVERITY (instant block)
  // ============================================================================
  static const List<String> threats = [
    // Direct threats
    'i will kill you', 'im going to kill you', 'im gonna kill you',
    'i\'ll kill you', 'gonna kill you', 'going to kill you',
    'kill yourself', 'kys', 'end yourself',
    'you should die', 'hope you die', 'wish you were dead',

    // Violence
    'shoot up', 'mass shooting', 'school shooting',
    'bomb threat', 'pipe bomb', 'suicide bomb',
    'rape you', 'gonna rape', 'deserve to be raped',

    // Doxing
    'here is his address', 'here\'s his address',
    'his phone number is', 'her phone number is',
    'swat him', 'swat her', 'swatting',
  ];

  // ============================================================================
  // ILLEGAL ACTIVITIES - HIGH SEVERITY (instant block)
  // ============================================================================
  static const List<String> illegalActivities = [
    // Child exploitation
    'cp', 'child porn', 'child pornography', 'underage',
    'lolita', 'jailbait', 'barely legal',

    // Drug sales
    'buy drugs', 'sell drugs', 'buying cocaine', 'selling meth',
    'buy weed dm me', 'selling pills', 'oxy for sale',
    'xanax for sale', 'molly for sale',

    // Fraud
    'credit card numbers', 'cvv codes', 'stolen accounts',
    'fake id', 'fake ids', 'counterfeit',
    'money laundering', 'wash money',

    // Hacking
    'ddos for hire', 'hack account', 'selling hacks',
    'stolen database', 'leaked passwords',
  ];

  // ============================================================================
  // SPAM & SCAMS - MEDIUM SEVERITY (flag for review or auto-block based on patterns)
  // ============================================================================
  static const List<String> spam = [
    // Too-good-to-be-true
    'make money fast', 'get rich quick', 'work from home money',
    'earn money per day', 'passive income guaranteed',
    'financial freedom now', 'million dollar opportunity',

    // Crypto scams
    'double your bitcoin', 'guaranteed returns', 'crypto giveaway',
    'send 1 btc get 2', 'elon musk giveaway', 'free crypto',

    // Phishing
    'verify your account now', 'account suspended',
    'confirm your password', 'unusual activity detected',
    'click here to claim', 'claim your prize',

    // MLM
    'join my team', 'be your own boss', 'pyramid scheme',
    'multilevel marketing', 'downline', 'upline',

    // Repeated characters (spam pattern)
    // Detected by regex in service
  ];

  // ============================================================================
  // HARASSMENT - MEDIUM TO HIGH SEVERITY
  // ============================================================================
  static const List<String> harassment = [
    // Severe personal attacks
    'you\'re worthless', 'you are worthless', 'piece of shit',
    'waste of space', 'nobody likes you', 'everyone hates you',
    'kill yourself', 'die in a fire', 'neck yourself',

    // Stalking
    'i know where you live', 'i\'m watching you',
    'i\'m following you', 'i see you', 'following you home',
  ];

  // ============================================================================
  // SELF-HARM - HIGH SEVERITY (block + potentially alert)
  // ============================================================================
  static const List<String> selfHarm = [
    'going to kill myself',
    'gonna kill myself',
    'planning my suicide',
    'suicide note',
    'cutting myself',
    'self harm',
    'self-harm',
    'ending it all',
    'not worth living',
  ];

  // ============================================================================
  // REGEX PATTERNS - For detecting sophisticated attempts to bypass filters
  // ============================================================================

  /// Detects repeated characters (e.g., "BUUUUUUY NOWWWWW")
  static final RegExp repeatedChars = RegExp(r'(.)\1{4,}');

  /// Detects excessive punctuation (e.g., "Click here!!!!!!!")
  static final RegExp excessivePunctuation = RegExp(r'[!?]{4,}');

  /// Detects suspicious URLs (multiple redirects, url shorteners in suspicious context)
  static final RegExp suspiciousUrls = RegExp(
    r'(bit\.ly|tinyurl|goo\.gl|t\.co)/[a-zA-Z0-9]+.*?(win|free|claim|prize|money)',
    caseSensitive: false,
  );

  /// Detects character substitution (e.g., "f*ck" vs "fuck", "a$$" vs "ass")
  static String normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[*@#\$]'), '') // Remove common substitution chars
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .replaceAll(RegExp(r'[^\w\s]'), ''); // Remove special chars
  }

  // ============================================================================
  // ALLOWLIST - Professional terms that might trigger false positives
  // ============================================================================
  static const List<String> allowlist = [
    // Tech terms
    'penetration testing', 'penetration test', 'pen test',
    'exploit development', 'vulnerability assessment',
    'kill process', 'kill thread', 'kill command',

    // Business terms
    'aggressive growth', 'killer feature', 'killer app',
    'target market', 'capture market', 'dominate market',

    // Startup terms
    'disrupt industry', 'destroy competition',
    'crush competitors', 'death spiral',
  ];

  // ============================================================================
  // CONTEXTUAL EXCEPTIONS - Patterns that are OK in professional context
  // ============================================================================

  /// Check if text contains professional/technical context that might use flagged words
  static bool hasProfessionalContext(String text) {
    final lowerText = text.toLowerCase();

    // Technical/security context
    if (lowerText.contains('security') ||
        lowerText.contains('testing') ||
        lowerText.contains('development') ||
        lowerText.contains('technical')) {
      return true;
    }

    // Business context
    if (lowerText.contains('market') ||
        lowerText.contains('strategy') ||
        lowerText.contains('business') ||
        lowerText.contains('startup')) {
      return true;
    }

    return false;
  }

  // ============================================================================
  // SEVERITY CONFIGURATION
  // ============================================================================

  static const Map<String, String> categorySeverity = {
    'sexual_explicit': 'high',
    'hate_speech': 'high',
    'threats': 'high',
    'illegal': 'high',
    'self_harm': 'high',
    'spam': 'medium',
    'harassment': 'medium',
  };

  // ============================================================================
  // COMBINED FILTERS BY SEVERITY
  // ============================================================================

  /// Get all HIGH severity terms (instant block)
  static List<String> get highSeverityTerms => [
        ...sexualExplicit,
        ...hateSpeech,
        ...threats,
        ...illegalActivities,
        ...selfHarm,
      ];

  /// Get all MEDIUM severity terms (flag for review)
  static List<String> get mediumSeverityTerms => [
        ...spam,
        ...harassment,
      ];

  /// Get all terms combined
  static List<String> get allTerms => [
        ...highSeverityTerms,
        ...mediumSeverityTerms,
      ];
}
