import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/business_application_service.dart';
import '../../services/file_upload_service.dart';
import 'payment_summary_page.dart';
import 'ecosystem_service_model.dart';

enum BusinessServiceType {
  taxHelp,
  businessRegistration,
  appDevelopment,
  marketing,
  employeeHiring,
  investorFinding,
  businessConsultation,
  marketResearch,
  patentFiling,
  softwareAudit,
}

enum PortalView {
  form,
  success,
}

/// Self-contained business services portal with dynamic form switching
class BusinessServicesPortal extends StatefulWidget {
  final BusinessServiceType initialService;

  const BusinessServicesPortal({
    super.key,
    required this.initialService,
  });

  @override
  State<BusinessServicesPortal> createState() => _BusinessServicesPortalState();
}

class _BusinessServicesPortalState extends State<BusinessServicesPortal> {
  final PortalView _currentView = PortalView.form;
  BusinessServiceType? _selectedService;
  final _formKey = GlobalKey<FormState>();

  // Form data maps for each service type
  final Map<String, dynamic> _formData = {};

  // Track uploaded files for each field
  final Map<String, List<Map<String, dynamic>>> _uploadedFiles = {};
  final Map<String, bool> _uploadingFiles = {};

  @override
  void initState() {
    super.initState();
    // Always expect initialService to be provided
    _selectedService = widget.initialService;
  }

  @override
  void dispose() {
    // Clean up any pending operations
    _formData.clear();
    _uploadedFiles.clear();
    _uploadingFiles.clear();
    super.dispose();
  }

  bool _isSubmitting = false;

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Get service type key from enum
        final serviceTypeKey = _getServiceTypeKey(_selectedService!);

        // Get applicant information from form data
        final applicantName = _formData['applicant_name']?.toString() ?? '';
        final applicantEmail = _formData['applicant_email']?.toString() ?? '';

        // Remove applicant info from form data since it's passed separately
        final formDataCopy = Map<String, dynamic>.from(_formData);
        formDataCopy.remove('applicant_name');
        formDataCopy.remove('applicant_email');

        // Save application as DRAFT before payment
        final result = await BusinessApplicationService.saveDraftApplication(
          serviceType: serviceTypeKey,
          applicantName: applicantName,
          applicantEmail: applicantEmail,
          formData: formDataCopy,
        );

        if (result['success'] == true) {
          final applicationId = result['application_id'] as int;
          final applicationData = result['data'] as Map<String, dynamic>;

          // Navigate to payment summary page
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PaymentSummaryPage(
                  applicationId: applicationId,
                  applicationData: applicationData,
                ),
              ),
            );
          }
        } else {
          _showErrorSnackBar(result['message'] ??
              'Failed to save application. Please try again.');
        }
      } catch (e) {
        _showErrorSnackBar('An error occurred: ${e.toString()}');
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getServiceTypeKey(BusinessServiceType serviceType) {
    switch (serviceType) {
      case BusinessServiceType.taxHelp:
        return 'tax_help';
      case BusinessServiceType.businessRegistration:
        return 'business_registration';
      case BusinessServiceType.appDevelopment:
        return 'app_development';
      case BusinessServiceType.marketing:
        return 'marketing';
      case BusinessServiceType.employeeHiring:
        return 'employee_hiring';
      case BusinessServiceType.investorFinding:
        return 'investor_finding';
      case BusinessServiceType.businessConsultation:
        return 'business_consultation';
      case BusinessServiceType.marketResearch:
        return 'market_research';
      case BusinessServiceType.patentFiling:
        return 'patent_filing';
      case BusinessServiceType.softwareAudit:
        return 'software_audit';
    }
  }

  void _backToEcosystem() async {
    // Ensure any pending operations are complete
    if (mounted) {
      // Small delay to ensure UI is stable
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _submitAnother() {
    // Go back to Ecosystem Applications page to select another service
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Always allow normal pop behavior to go back to Ecosystem Applications
        return true;
      },
      child: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside form fields
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(_getAppBarTitle()),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                // Always go back to Ecosystem Applications
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.8),
                ],
              ),
            ),
            child: _buildCurrentView(),
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentView) {
      case PortalView.form:
        return _getServiceTitle(_selectedService!);
      case PortalView.success:
        return 'Request Submitted';
    }
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case PortalView.form:
        return _buildServiceForm();
      case PortalView.success:
        return _buildSuccessView();
    }
  }

  Widget _buildServiceForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Service Header
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getServiceTitle(_selectedService!),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getServiceDescription(_selectedService!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),

          // Dynamic Form Fields
          ..._buildFormFields(_selectedService!),

          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_forward, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Review & Pay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Back Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                // Always go back to Ecosystem Applications
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: const Color(0xFF4CAF50)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back to Ecosystem',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Request Submitted Successfully!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4CAF50),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Thank you for your ${_getServiceTitle(_selectedService!).toLowerCase()} request. Our team will review your submission and get back to you within 24-48 hours.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitAnother,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit Another Request',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _backToEcosystem,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: const Color(0xFF4CAF50)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back to Ecosystem',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getServiceTitle(BusinessServiceType service) {
    switch (service) {
      case BusinessServiceType.taxHelp:
        return 'Tax Help';
      case BusinessServiceType.businessRegistration:
        return 'Business Registration & Legal';
      case BusinessServiceType.appDevelopment:
        return 'App & Web Development';
      case BusinessServiceType.marketing:
        return 'Marketing & Advertisement';
      case BusinessServiceType.employeeHiring:
        return 'Employee Hiring';
      case BusinessServiceType.investorFinding:
        return 'Investor Finding';
      case BusinessServiceType.businessConsultation:
        return 'Business Consultation';
      case BusinessServiceType.marketResearch:
        return 'Market Research - Product Fit';
      case BusinessServiceType.patentFiling:
        return 'Product Patent Filing';
      case BusinessServiceType.softwareAudit:
        return 'Software Audit & Security';
    }
  }

  String _getServiceDescription(BusinessServiceType service) {
    switch (service) {
      case BusinessServiceType.taxHelp:
        return 'Get professional assistance with tax preparation, planning, or resolving IRS issues from certified experts.';
      case BusinessServiceType.businessRegistration:
        return 'Register your new business correctly or get help with essential legal compliance and documentation.';
      case BusinessServiceType.appDevelopment:
        return 'Bring your digital idea to life with our expert development teams for mobile apps and websites.';
      case BusinessServiceType.marketing:
        return 'Grow your audience and increase sales with targeted marketing campaigns and advertising strategies.';
      case BusinessServiceType.employeeHiring:
        return 'Find, vet, and hire the right talent for your team with our streamlined recruitment services.';
      case BusinessServiceType.investorFinding:
        return 'Prepare your pitch and connect with potential investors to secure funding for your venture.';
      case BusinessServiceType.businessConsultation:
        return 'Get strategic advice and expert guidance to optimize your business operations and growth strategy.';
      case BusinessServiceType.marketResearch:
        return 'Validate your product-market fit with comprehensive market research, competitor analysis, and customer insights.';
      case BusinessServiceType.patentFiling:
        return 'Protect your innovative ideas and products with professional patent filing and intellectual property services.';
      case BusinessServiceType.softwareAudit:
        return 'Comprehensive software and security audit to ensure your application is robust, secure, and scalable.';
    }
  }

  List<String> _getServiceFeatures(BusinessServiceType type) {
    try {
      final serviceData = ecosystemServices.firstWhere((s) => s.type == type);
      return serviceData.features.map((f) => f.title).toList();
    } catch (e) {
      return [];
    }
  }

  List<Widget> _buildFormFields(BusinessServiceType service) {
    List<Widget> commonFields = [
      // Contact Information (required for all services)
      Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildTextInputField('Full Name *', 'applicant_name'),
            const SizedBox(height: 12),
            _buildEmailInputField('Email Address *', 'applicant_email'),
          ],
        ),
      ),
    ];

    List<Widget> serviceSpecificFields;
    switch (service) {
      case BusinessServiceType.taxHelp:
        serviceSpecificFields = _buildTaxHelpForm();
        break;
      case BusinessServiceType.businessRegistration:
        serviceSpecificFields = _buildBusinessRegistrationForm();
        break;
      case BusinessServiceType.appDevelopment:
        serviceSpecificFields = _buildAppDevelopmentForm();
        break;
      case BusinessServiceType.marketing:
        serviceSpecificFields = _buildMarketingForm();
        break;
      case BusinessServiceType.employeeHiring:
        serviceSpecificFields = _buildEmployeeHiringForm();
        break;
      case BusinessServiceType.investorFinding:
        serviceSpecificFields = _buildInvestorFindingForm();
        break;
      case BusinessServiceType.businessConsultation:
        serviceSpecificFields = _buildBusinessConsultationForm();
        break;
      case BusinessServiceType.marketResearch:
        serviceSpecificFields = _buildMarketResearchForm();
        break;
      case BusinessServiceType.patentFiling:
        serviceSpecificFields = _buildPatentFilingForm();
        break;
      case BusinessServiceType.softwareAudit:
        serviceSpecificFields = _buildSoftwareAuditForm();
        break;
    }

    return [...commonFields, ...serviceSpecificFields];
  }

  List<Widget> _buildTaxHelpForm() {
    return [
      _buildDropdownField(
        'Type of Entity',
        ['Sole Proprietor', 'LLC', 'S-Corp', 'C-Corp', 'Individual'],
        'entityType',
      ),
      _buildDropdownField(
        'Type of Help Needed',
        _getServiceFeatures(BusinessServiceType.taxHelp),
        'helpType',
      ),
      _buildDropdownField(
        'Approximate Annual Revenue',
        ['<\$50k', '\$50k - \$250k', '\$250k - \$1M', '\$1M - \$5M', '>\$5M'],
        'revenue',
      ),
      _buildDropdownField(
        'Tax Year(s) in Question',
        ['2024', '2023', '2022', '2021', '2020', 'Multiple Years', 'Other'],
        'taxYear',
      ),
      _buildTextInputField('Current Tax Status', 'currentTaxStatus'),
      _buildDropdownField(
        'Complexity',
        ['Simple', 'Moderate', 'Complex'],
        'complexity',
      ),
      _buildDatePickerField('Specific Deadline', 'deadline'),
      _buildTextAreaField(
        'Brief description of the tax situation or specific questions',
        'taxDescription',
      ),
      _buildFileUploadField('Upload relevant documents',
          fieldKey: 'tax_documents'),
    ];
  }

  List<Widget> _buildBusinessRegistrationForm() {
    return [
      _buildDropdownField(
        'Service Needed',
        _getServiceFeatures(BusinessServiceType.businessRegistration),
        'serviceNeeded',
      ),
      _buildDropdownField(
        'Type of Business Formation',
        ['LLC', 'S-Corp', 'C-Corp', 'Partnership', 'Sole Proprietor'],
        'businessFormation',
      ),
      _buildDropdownField(
        'State of Incorporation/Formation',
        [
          'Delaware',
          'Nevada',
          'California',
          'Texas',
          'Florida',
          'New York',
          'Other'
        ],
        'stateOfIncorporation',
      ),
      _buildTextInputField('Physical Business Address', 'businessAddress'),
      _buildDropdownField(
        'Number of Founders/Partners',
        ['1', '2', '3', '4', '5+'],
        'numberOfFounders',
      ),
      _buildDropdownField(
        'Timeline for Completion',
        ['ASAP', '1-2 weeks', '1 month', '2-3 months', 'Flexible'],
        'timeline',
      ),
      _buildTextAreaField(
        'Brief description of your business or specific questions',
        'businessDescription',
      ),
      _buildFileUploadField('Upload relevant documents',
          fieldKey: 'business_documents'),
    ];
  }

  List<Widget> _buildAppDevelopmentForm() {
    return [
      _buildDropdownField(
        'Service Type',
        _getServiceFeatures(BusinessServiceType.appDevelopment),
        'developmentType',
      ),
      _buildDropdownField(
        'Project Stage',
        ['Idea Stage', 'Wireframes/Mockups', 'MVP', 'Enhancement', 'Redesign'],
        'projectStage',
      ),
      _buildTextInputField('Target Audience', 'targetAudience'),
      _buildTextAreaField('Core Features Needed', 'coreFeatures'),
      _buildTextInputField(
          'Competitor Links (comma-separated)', 'competitorLinks'),
      _buildDropdownField(
        'Technology Preferences',
        [
          'No Preference',
          'React/Node.js',
          'Python/Django',
          'Flutter',
          'React Native',
          'Other'
        ],
        'technologyPreferences',
      ),
      _buildDropdownField(
        'Budget Range',
        [
          '<\$10k',
          '\$10k-25k',
          '\$25k-50k',
          '\$50k-100k',
          '\$100k+',
          'Equity Only'
        ],
        'budget',
      ),
      _buildTextAreaField('Project description and specific requirements',
          'projectDescription'),
      _buildFileUploadField('Upload wireframes, mockups, or requirements',
          fieldKey: 'app_requirements'),
    ];
  }

  List<Widget> _buildMarketingForm() {
    return [
      _buildDropdownField(
        'Marketing Goal',
        [
          'Brand Awareness',
          'Lead Generation',
          'Sales Growth',
          'Social Media Engagement'
        ],
        'marketingGoal',
      ),
      _buildDropdownField(
        'Service of Interest',
        _getServiceFeatures(BusinessServiceType.marketing),
        'serviceInterest',
      ),
      _buildTextAreaField('Key Products/Services to Market', 'keyProducts'),
      _buildTextAreaField('Unique Selling Proposition (USP)', 'usp'),
      _buildTextInputField(
          'Key Competitors (comma-separated)', 'keyCompetitors'),
      _buildTextAreaField('Target Audience Description', 'targetAudience'),
      _buildDropdownField(
        'Estimated Monthly Budget',
        ['<\$500', '\$500 - \$2k', '\$2k - \$10k', '\$10k - \$50k', '>\$50k'],
        'monthlyBudget',
      ),
      _buildTextInputField(
          'Link to current website or social media profiles', 'websiteLink'),
      _buildFileUploadField(
          'Upload marketing materials, brand assets, or examples',
          fieldKey: 'marketing_materials'),
    ];
  }

  List<Widget> _buildEmployeeHiringForm() {
    return [
      _buildTextInputField('Job Title of Role to be Filled', 'jobTitle'),
      _buildDropdownField(
        'Department',
        [
          'Engineering',
          'Marketing',
          'Sales',
          'Operations',
          'Finance',
          'HR',
          'Other'
        ],
        'department',
      ),
      _buildDropdownField(
        'Type of Employment',
        ['Full-Time', 'Part-Time', 'Contract', 'Freelance'],
        'employmentType',
      ),
      _buildDropdownField(
        'Required Experience Level',
        ['Entry-Level', 'Mid-Level', 'Senior', 'Executive'],
        'experienceLevel',
      ),
      _buildDropdownField(
        'Salary Range',
        [
          '<\$50k',
          '\$50k-75k',
          '\$75k-100k',
          '\$100k-150k',
          '\$150k+',
          'Equity Only'
        ],
        'salaryRange',
      ),
      _buildDropdownField(
        'Location',
        ['Remote', 'Hybrid', 'On-site', 'Flexible'],
        'location',
      ),
      _buildDatePickerField('Desired Start Date', 'startDate'),
      _buildTextAreaField(
          'Key responsibilities and qualifications for the role',
          'roleDescription'),
      _buildNumberInputField('Number of positions to fill', 'positionCount'),
      _buildFileUploadField(
          'Upload job description, company info, or requirements',
          fieldKey: 'hiring_documents'),
    ];
  }

  List<Widget> _buildInvestorFindingForm() {
    return [
      _buildDropdownField(
        'Service Needed',
        _getServiceFeatures(BusinessServiceType.investorFinding),
        'serviceNeeded',
      ),
      _buildDropdownField(
        'Current Funding Stage',
        ['Pre-Seed', 'Seed', 'Series A', 'Bootstrapped'],
        'fundingStage',
      ),
      _buildTextInputField('Amount of Capital Sought (\$)', 'capitalAmount'),
      _buildTextInputField('Industry/Sector', 'industry'),
      _buildTextAreaField('Traction/Key Metrics', 'traction'),
      _buildTextAreaField('Use of Funds', 'useOfFunds'),
      _buildTextInputField(
          'Investment Deck Link (optional)', 'investmentDeckLink'),
      _buildTextAreaField('Previous Funding History', 'previousFunding'),
      _buildTextAreaField(
          'Brief Company Description (Elevator Pitch)', 'companyDescription'),
      _buildFileUploadField(
          'Upload pitch deck, executive summary, or business plan',
          fieldKey: 'investor_documents'),
    ];
  }

  List<Widget> _buildBusinessConsultationForm() {
    return [
      _buildDropdownField(
        'Type of Consultation Needed',
        _getServiceFeatures(BusinessServiceType.businessConsultation),
        'consultationType',
      ),
      _buildDropdownField(
        'Business Stage',
        [
          'Idea Stage',
          'Startup (0-2 years)',
          'Growth Stage (2-5 years)',
          'Established (5+ years)'
        ],
        'businessStage',
      ),
      _buildTextAreaField('Specific Challenges', 'specificChallenges'),
      _buildTextAreaField('Desired Outcomes', 'desiredOutcomes'),
      _buildDropdownField(
        'Urgency',
        [
          'Immediate (1-2 weeks)',
          'Short-term (1 month)',
          'Medium-term (2-3 months)',
          'Long-term (3+ months)'
        ],
        'urgency',
      ),
      _buildTextInputField('Key Stakeholders Involved', 'keyStakeholders'),
      _buildDropdownField(
        'Industry/Sector',
        [
          'Technology',
          'Healthcare',
          'Finance',
          'Retail/E-commerce',
          'Manufacturing',
          'Services',
          'Food & Beverage',
          'Other'
        ],
        'industry',
      ),
      _buildDropdownField(
        'Company Size',
        [
          'Solo Founder',
          '2-5 employees',
          '6-20 employees',
          '21-50 employees',
          '50+ employees'
        ],
        'companySize',
      ),
      _buildTextAreaField(
          'Brief description of your business and current challenges',
          'businessDescription'),
      _buildDropdownField(
        'Preferred Consultation Format',
        [
          'One-time Session',
          'Multiple Sessions',
          'Ongoing Mentorship',
          'Workshop/Training'
        ],
        'consultationFormat',
      ),
      _buildDropdownField(
        'Budget Range for Consultation',
        [
          '<\$500',
          '\$500 - \$1,500',
          '\$1,500 - \$5,000',
          '\$5,000 - \$15,000',
          '>\$15,000'
        ],
        'consultationBudget',
      ),
      _buildFileUploadField(
          'Upload business plan, financial statements, or relevant documents',
          fieldKey: 'consultation_documents'),
    ];
  }

  List<Widget> _buildMarketResearchForm() {
    return [
      _buildDropdownField(
        'Type of Market Research',
        _getServiceFeatures(BusinessServiceType.marketResearch),
        'researchType',
      ),
      _buildDropdownField(
        'Product/Service Stage',
        [
          'Concept/Idea',
          'MVP/Prototype',
          'Beta/Testing',
          'Launched',
          'Mature Product'
        ],
        'productStage',
      ),
      _buildTextAreaField('Product/Service Description', 'productDescription'),
      _buildTextAreaField('Target Customer Description', 'targetCustomer'),
      _buildTextInputField('Industry/Market Sector', 'industry'),
      _buildTextAreaField('Key Questions You Want Answered', 'keyQuestions'),
      _buildDropdownField(
        'Geographic Market Focus',
        [
          'Local/Regional',
          'National',
          'International',
          'Global',
          'Online/Digital'
        ],
        'geographicFocus',
      ),
      _buildDropdownField(
        'Research Timeline',
        [
          'Rush (1-2 weeks)',
          'Standard (3-4 weeks)',
          'Comprehensive (6-8 weeks)',
          'Ongoing'
        ],
        'researchTimeline',
      ),
      _buildDropdownField(
        'Budget Range',
        ['<\$1k', '\$1k-3k', '\$3k-7k', '\$7k-15k', '\$15k+'],
        'researchBudget',
      ),
      _buildTextAreaField(
          'Current Market Assumptions or Hypotheses', 'marketAssumptions'),
      _buildTextInputField('Competitor Names (comma-separated)', 'competitors'),
      _buildTextAreaField(
          'Specific Research Deliverables Needed', 'deliverables'),
      _buildFileUploadField(
          'Upload existing research, business plan, or product materials',
          fieldKey: 'research_documents'),
    ];
  }

  List<Widget> _buildPatentFilingForm() {
    return [
      _buildDropdownField(
        'Service Needed',
        _getServiceFeatures(BusinessServiceType.patentFiling),
        'serviceNeeded',
      ),
      _buildDropdownField(
        'Type of Patent',
        [
          'Utility Patent',
          'Design Patent',
          'Provisional Patent',
          'Plant Patent',
          'Not Sure'
        ],
        'patentType',
      ),
      _buildDropdownField(
        'Invention Stage',
        [
          'Concept/Idea',
          'Prototype Built',
          'Tested/Validated',
          'In Production',
          'Commercially Available'
        ],
        'inventionStage',
      ),
      _buildTextAreaField(
          'Invention/Product Description', 'inventionDescription'),
      _buildTextAreaField(
          'What Makes Your Invention Unique?', 'uniqueFeatures'),
      _buildDropdownField(
        'Industry Category',
        [
          'Technology/Software',
          'Medical/Healthcare',
          'Mechanical/Engineering',
          'Chemical/Pharmaceutical',
          'Consumer Products',
          'Automotive',
          'Electronics',
          'Other'
        ],
        'industryCategory',
      ),
      _buildDropdownField(
        'Patent Search Completed?',
        [
          'Yes - Professional Search',
          'Yes - Basic Search',
          'No - Need Help',
          'Not Sure'
        ],
        'patentSearchStatus',
      ),
      _buildTextAreaField('Known Prior Art or Similar Patents', 'priorArt'),
      _buildDropdownField(
        'Commercial Plans',
        [
          'License to Others',
          'Manufacture/Sell Myself',
          'Prevent Others from Using',
          'Not Sure'
        ],
        'commercialPlans',
      ),
      _buildDropdownField(
        'Geographic Protection Needed',
        [
          'US Only',
          'US + Canada',
          'US + Europe',
          'US + Asia',
          'Worldwide',
          'Not Sure'
        ],
        'geographicProtection',
      ),
      _buildDropdownField(
        'Timeline Urgency',
        [
          'Rush (ASAP)',
          'Standard (2-3 months)',
          'No Rush (6+ months)',
          'Flexible'
        ],
        'timeline',
      ),
      _buildDropdownField(
        'Budget Range',
        [
          '<\$5k',
          '\$5k-10k',
          '\$10k-20k',
          '\$20k-50k',
          '\$50k+',
          'Need Consultation'
        ],
        'patentBudget',
      ),
      _buildTextAreaField(
          'Additional Details or Special Considerations', 'additionalDetails'),
      _buildFileUploadField(
          'Upload invention drawings, prototypes, or technical documents',
          fieldKey: 'patent_documents'),
    ];
  }

  Widget _buildTextInputField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _formData[key]?.toString(),
            onSaved: (value) => _formData[key] = value,
            onChanged: (value) => _formData[key] = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailInputField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _formData[key]?.toString(),
            keyboardType: TextInputType.emailAddress,
            onSaved: (value) => _formData[key] = value,
            onChanged: (value) => _formData[key] = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email address is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInputField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _formData[key]?.toString(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSaved: (value) => _formData[key] = int.tryParse(value ?? '0'),
            onChanged: (value) => _formData[key] = int.tryParse(value) ?? 0,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextAreaField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _formData[key]?.toString(),
            maxLines: 3,
            onSaved: (value) => _formData[key] = value,
            onChanged: (value) => _formData[key] = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String key) {
    // Ensure the current value is valid (exists in options list)
    final currentValue = _formData[key]?.toString();
    final validValue = currentValue != null && options.contains(currentValue)
        ? currentValue
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: validValue,
            onSaved: (value) => _formData[key] = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an option';
              }
              return null;
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
            ),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                _formData[key] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadField(String label, {String? fieldKey}) {
    final key = fieldKey ?? label.toLowerCase().replaceAll(' ', '_');
    final uploadedFiles = _uploadedFiles[key] ?? [];
    final isUploading = _uploadingFiles[key] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),

          // Upload Area
          Container(
            width: double.infinity,
            height: uploadedFiles.isEmpty ? 110 : null,
            constraints: uploadedFiles.isEmpty
                ? null
                : const BoxConstraints(minHeight: 60),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: isUploading ? null : () => _handleFileUpload(key),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: uploadedFiles.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isUploading) ...[
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Uploading files...',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ] else ...[
                              Icon(
                                Icons.cloud_upload,
                                size: 28,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Click to upload files',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'PDF, DOC, images, etc. (Max 50MB total)',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey.shade500,
                                    ),
                              ),
                            ],
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Uploaded files list
                            ...uploadedFiles.map(
                                (file) => _buildUploadedFileItem(file, key)),

                            // Add more files button
                            if (!isUploading)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton.icon(
                                  onPressed: () => _handleFileUpload(key),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add more files'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedFileItem(Map<String, dynamic> file, String fieldKey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(file['type']),
            size: 20,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file['name'] ?? 'Unknown file',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  file['size_formatted'] ?? 'Unknown size',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeFile(fieldKey, file),
            icon: Icon(
              Icons.close,
              size: 18,
              color: Colors.red.shade600,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String? fileType) {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.attach_file;
    }
  }

  Future<void> _handleFileUpload(String fieldKey) async {
    try {
      setState(() {
        _uploadingFiles[fieldKey] = true;
      });

      final files = await FileUploadService.pickFiles(allowMultiple: true);
      if (files == null || files.isEmpty) {
        setState(() {
          _uploadingFiles[fieldKey] = false;
        });
        return;
      }

      // Validate files
      for (final file in files) {
        final validation = FileUploadService.validateFile(file);
        if (validation != null) {
          _showErrorSnackBar('${file.name}: $validation');
          setState(() {
            _uploadingFiles[fieldKey] = false;
          });
          return;
        }
      }

      // Generate temporary application ID for file organization
      final tempAppId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

      // Upload files
      final uploadedFileData = await FileUploadService.uploadMultipleFiles(
        files: files,
        applicationId: tempAppId,
      );

      if (uploadedFileData.isNotEmpty) {
        setState(() {
          _uploadedFiles[fieldKey] = [
            ...(_uploadedFiles[fieldKey] ?? []),
            ...uploadedFileData
          ];
          // Store file URLs in form data
          _formData['${fieldKey}_files'] = _uploadedFiles[fieldKey];
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error uploading files: ${e.toString()}');
    } finally {
      setState(() {
        _uploadingFiles[fieldKey] = false;
      });
    }
  }

  void _removeFile(String fieldKey, Map<String, dynamic> file) {
    setState(() {
      _uploadedFiles[fieldKey]?.remove(file);
      if (_uploadedFiles[fieldKey]?.isEmpty ?? true) {
        _uploadedFiles.remove(fieldKey);
        _formData.remove('${fieldKey}_files');
      } else {
        _formData['${fieldKey}_files'] = _uploadedFiles[fieldKey];
      }
    });

    // Delete file from storage
    final filePath = file['path'] as String?;
    if (filePath != null) {
      FileUploadService.deleteFile(filePath);
    } else {
      // Try to extract path from URL for legacy files
      final url = file['url'] as String?;
      if (url != null) {
        try {
          // URL format: .../storage/v1/object/public/bucketName/path/to/file
          final uri = Uri.parse(url);
          final segments = uri.pathSegments;
          final publicIndex = segments.indexOf('public');
          if (publicIndex != -1 && publicIndex + 2 < segments.length) {
            // public/bucketName/path...
            final pathSegments = segments.skip(publicIndex + 2);
            final extractedPath = pathSegments.join('/');
            FileUploadService.deleteFile(extractedPath);
          }
        } catch (e) {
          debugPrint('Error parsing file URL for deletion: $e');
        }
      }
    }
  }

  Widget _buildDatePickerField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            readOnly: true,
            onTap: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: const Color(0xFF4CAF50),
                          ),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedDate != null) {
                _formData[key] = pickedDate.toIso8601String().split('T')[0];
                // Force rebuild to show selected date
                setState(() {});
              }
            },
            controller: TextEditingController(
              text: _formData[key]?.toString() ?? '',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a date';
              }
              return null;
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
              suffixIcon: const Icon(Icons.calendar_today),
              hintText: 'Select date',
            ),
          ),
        ],
      ),
    );
  }
  List<Widget> _buildSoftwareAuditForm() {
    return [
      _buildDropdownField(
        'Audit Type',
        _getServiceFeatures(BusinessServiceType.softwareAudit),
        'auditType',
      ),
      _buildDropdownField(
        'Platform',
        ['Mobile App', 'Web App', 'Backend/API', 'Full Stack'],
        'platform',
      ),
      _buildTextInputField('Tech Stack (e.g., Flutter, Node.js)', 'techStack'),
      _buildDropdownField(
        'Current Status',
        ['In Development', 'Live/Production', 'Legacy Codebase'],
        'currentStatus',
      ),
      _buildTextAreaField('Specific concerns or areas to focus on', 'auditConcerns'),
      _buildTextInputField('Link to Codebase/Repo (optional)', 'repoLink'),
      _buildFileUploadField('Upload architecture diagrams or docs',
          fieldKey: 'audit_documents'),
    ];
  }
}
