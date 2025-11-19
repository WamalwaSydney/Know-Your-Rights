// lib/core/services/legal_library_service.dart

import 'package:legal_ai/core/models/legal_resource.dart';

/// Service that provides all legal guides, definitions,
/// and world-class professional legal document templates.
class LegalLibraryService {
  /// Returns all legal resources (templates, guides, definitions)
  List<LegalResource> getResources() {
    return [
      // ---------------------------
      // 🧾 WORLD-CLASS TEMPLATES
      // ---------------------------

      LegalResource(
        title: 'Non-Disclosure Agreement (NDA)',
        description:
        'A professionally drafted NDA template used to protect confidential information when sharing sensitive data between parties.',
        type: 'Template',
        url: 'dynamic:nda', // special keyword = rendered by AI
      ),
      LegalResource(
        title: 'Residential Lease Agreement',
        description:
        'A legally compliant lease agreement outlining landlord–tenant rights, obligations, and property terms.',
        type: 'Template',
        url: 'dynamic:lease',
      ),
      LegalResource(
        title: 'Last Will & Testament',
        description:
        'A structured and legally sound will template that defines beneficiaries, executors, and distribution of assets.',
        type: 'Template',
        url: 'dynamic:will',
      ),
      LegalResource(
        title: 'Employment Contract',
        description:
        'A detailed employment agreement covering duties, compensation, IP ownership, termination terms, and confidentiality.',
        type: 'Template',
        url: 'dynamic:employment',
      ),
      LegalResource(
        title: 'Loan Agreement',
        description:
        'A financial agreement detailing repayment terms, interest, collateral, and borrower–lender obligations.',
        type: 'Template',
        url: 'dynamic:loan',
      ),
      LegalResource(
        title: 'Power of Attorney (POA)',
        description:
        'A highly-polished POA document granting someone authority to act on your behalf.',
        type: 'Template',
        url: 'dynamic:poa',
      ),

      // ---------------------------
      // 📘 DEFINITIONS
      // ---------------------------

      LegalResource(
        title: 'Force Majeure',
        description:
        'A clause that frees parties from liability when an unforeseeable event beyond their control prevents contract performance.',
        type: 'Definition',
      ),
      LegalResource(
        title: 'Habeas Corpus',
        description:
        'A legal action requiring that a detained individual be brought before a court to justify their detention.',
        type: 'Definition',
      ),
      LegalResource(
        title: 'Indemnity Clause',
        description:
        'A provision where one party agrees to compensate the other for losses or damages arising from specific events.',
        type: 'Definition',
      ),
      LegalResource(
        title: 'Arbitration',
        description:
        'A dispute resolution mechanism where parties use a neutral arbitrator instead of going to court.',
        type: 'Definition',
      ),

      // ---------------------------
      // 📚 GUIDES
      // ---------------------------

      LegalResource(
        title: 'Guide to Small Claims Court',
        description:
        'A beginner-friendly walk-through on how to prepare, file, and present a small claims case.',
        type: 'Guide',
        url: 'https://www.judiciary.go.ke/small-claims-overview/',
      ),
      LegalResource(
        title: 'Understanding Your Employment Contract',
        description:
        'A breakdown of key clauses, red flags, and rights in an employment agreement.',
        type: 'Guide',
        url: 'https://www.labour.go.ke/',
      ),
      LegalResource(
        title: 'How to Create a Legally Valid Contract',
        description:
        'Covers offer, acceptance, consideration, capacity, and enforceability.',
        type: 'Guide',
        url: 'https://www.law.cornell.edu/wex/contract',
      ),
    ];
  }

  /// Get a specific template by its key
  String? getTemplateByKey(String key) {
    final templates = getDynamicTemplates();
    return templates[key];
  }

  /// Get template with user data filled in
  String getFilledTemplate(String key, Map<String, String> userData) {
    String? template = getTemplateByKey(key);
    if (template == null) return '';

    // Replace placeholders with user data
    userData.forEach((placeholder, value) {
      template = template!.replaceAll('[$placeholder]', value);
    });

    return template!;
  }

  /// Get all available template keys
  List<String> getTemplateKeys() {
    return getDynamicTemplates().keys.toList();
  }

  /// Check if a template key exists
  bool hasTemplate(String key) {
    return getDynamicTemplates().containsKey(key);
  }

  /// ---------------------------------------------------------
  ///  PROFESSIONAL DYNAMIC LEGAL TEMPLATES
  ///  These are rendered by your AI + PDF generator.
  /// ---------------------------------------------------------
  Map<String, String> getDynamicTemplates() {
    return {
      'nda': _ndaTemplate(),
      'lease': _leaseTemplate(),
      'will': _willTemplate(),
      'employment': _employmentContractTemplate(),
      'loan': _loanAgreementTemplate(),
      'poa': _poaTemplate(),
    };
  }

  // ------------------------------------------------------------
  //  TEMPLATES BELOW — WORLD-CLASS, PROFESSIONAL, AI-READY
  // ------------------------------------------------------------

  String _ndaTemplate() => '''
# NON-DISCLOSURE AGREEMENT (NDA)

This Non-Disclosure Agreement ("Agreement") is entered into on **[Date]** between:

**[Disclosing Party Name]**, located at **[Disclosing Party Address]**,  
and  
**[Receiving Party Name]**, located at **[Receiving Party Address]**.

## 1. Definition of Confidential Information
Confidential Information includes all proprietary, technical, financial, business, and strategic information disclosed orally, electronically, or in writing.

## 2. Obligations of Receiving Party
The Receiving Party shall:
- Maintain strict confidentiality;
- Not disclose any Confidential Information to third parties;
- Limit internal access to authorized personnel only.

## 3. Exclusions
Information is not confidential if it:
- Becomes publicly available without breach;
- Was already known prior to disclosure;
- Is independently developed without reference to Confidential Information.

## 4. Term
This Agreement remains in effect for **[Duration]** from the date of signing.

## 5. Remedies
Unauthorized disclosure may result in injunctive relief and financial damages.

## 6. Governing Law
This Agreement is governed by the laws of **[Jurisdiction]**.

## 7. Signatures

______________________  
**[Disclosing Party Name]**  
Disclosing Party  
Date: **[Date]**

______________________  
**[Receiving Party Name]**  
Receiving Party  
Date: **[Date]**

---

**DISCLAIMER**: This document is a template for informational purposes only and does not constitute legal advice. Please consult with a licensed attorney before using this agreement.
''';

  String _leaseTemplate() => '''
# RESIDENTIAL LEASE AGREEMENT

This Lease Agreement ("Agreement") is made on **[Date]**, between:

**Landlord:** **[Landlord Name]**  
**Address:** **[Landlord Address]**

**Tenant:** **[Tenant Name]**  
**Address:** **[Tenant Address]**

## 1. Property
The Landlord leases the residential property located at:  
**[Property Address]**

## 2. Term
The lease begins on **[Start Date]** and continues until **[End Date]**.

## 3. Rent
Monthly rent: **[Monthly Rent Amount]** payable on/before the **[Payment Day]** of each month.

Payment method: **[Payment Method]**

## 4. Security Deposit
The Tenant shall pay a security deposit of **[Security Deposit Amount]** which shall be refundable upon termination, subject to property condition and any damages.

## 5. Utilities
The following utilities are included/excluded:
- **[Utility Details]**

## 6. Maintenance & Repairs
Tenant must maintain the premises in good condition. Repairs costing over **[Repair Threshold Amount]** are the Landlord's responsibility unless caused by Tenant negligence.

## 7. Restrictions
The Tenant agrees to:
- Not sublease without written consent
- Not make alterations without permission
- **[Additional Restrictions]**

## 8. Termination
Either party may terminate with **[Notice Period]** written notice.

## 9. Governing Law
This Agreement is governed by **[Jurisdiction]** law.

## 10. Signatures

______________________  
**[Landlord Name]**  
Landlord  
Date: **[Date]**

______________________  
**[Tenant Name]**  
Tenant  
Date: **[Date]**

---

**DISCLAIMER**: This document is a template for informational purposes only and does not constitute legal advice. Please consult with a licensed attorney before using this agreement.
''';

  String _willTemplate() => '''
# LAST WILL & TESTAMENT

I, **[Testator Full Name]**, of **[Testator Address]**, being of sound mind and disposing memory, hereby declare this to be my Last Will and Testament, revoking all previous wills and codicils.

## 1. Executor
I appoint **[Executor Name]**, residing at **[Executor Address]**, as the Executor of my estate.

If **[Executor Name]** is unable or unwilling to serve, I appoint **[Alternate Executor Name]** as alternate Executor.

## 2. Beneficiaries and Distribution
I direct that my assets shall be distributed as follows:

### Real Property
- **[Property Description]** shall go to **[Beneficiary Name]**

### Financial Assets
- **[Percentage]** of my estate to **[Beneficiary Name]**
- **[Percentage]** of my estate to **[Beneficiary Name]**

### Personal Property
- **[Item Description]** to **[Beneficiary Name]**

### Residual Estate
All remaining assets shall be distributed **[Distribution Instructions]**

## 3. Guardianship of Minor Children
Should I pass leaving minor children, I appoint **[Guardian Name]**, residing at **[Guardian Address]**, as guardian of my children:
- **[Child Name]**
- **[Child Name]**

## 4. Debts and Taxes
All just debts, funeral expenses, and estate taxes shall be paid from my estate before distribution to beneficiaries.

## 5. Special Instructions
**[Special Instructions or Wishes]**

## 6. Signatures

Signed on **[Date]** at **[Location]**.

______________________  
**[Testator Full Name]**  
Testator

## Witness Attestation

We, the undersigned witnesses, declare that the Testator signed this Will in our presence, and that we signed as witnesses in the Testator's presence and in the presence of each other.

______________________  
**[Witness 1 Name]**  
Address: **[Witness 1 Address]**  
Date: **[Date]**

______________________  
**[Witness 2 Name]**  
Address: **[Witness 2 Address]**  
Date: **[Date]**

---

**DISCLAIMER**: This document is a template for informational purposes only and does not constitute legal advice. Wills have specific legal requirements that vary by jurisdiction. Please consult with a licensed attorney to ensure your will is valid and enforceable.
''';

  String _employmentContractTemplate() => '''
# EMPLOYMENT AGREEMENT

This Employment Agreement ("Agreement") is made on **[Date]** between:

**Employer:** **[Company Name]**  
**Address:** **[Company Address]**  
**Registration Number:** **[Company Registration]**

**Employee:** **[Employee Full Name]**  
**Address:** **[Employee Address]**  
**ID Number:** **[Employee ID]**

## 1. Position and Duties
The Employee is hired as **[Job Title]** reporting to **[Supervisor/Manager]**.

The Employee agrees to perform all duties related to the position including:
- **[Responsibility 1]**
- **[Responsibility 2]**
- **[Responsibility 3]**
- **[Additional Responsibilities]**

## 2. Term of Employment
Employment begins on **[Start Date]**.

This is a **[Employment Type]** position (permanent/fixed-term/probationary).

**[If probationary: Probationary period of [Duration] with review on [Review Date]]**

## 3. Compensation
**Base Salary:** **[Annual/Monthly Salary Amount]**, payable **[Payment Frequency]**.

**Additional Compensation:**
- **[Bonus/Commission Details]**
- **[Other Compensation]**

## 4. Benefits
The Employee shall receive the following benefits:
- **[Health Insurance]**
- **[Retirement/Pension]**
- **[Vacation Days]**
- **[Sick Leave]**
- **[Other Benefits]**

## 5. Working Hours
Standard working hours: **[Hours per Week]**  
Schedule: **[Work Schedule]**

## 6. Confidentiality
The Employee agrees to maintain strict confidentiality regarding:
- Trade secrets and proprietary information
- Business strategies and plans
- Client and customer information
- Financial data
- **[Additional Confidential Matters]**

## 7. Intellectual Property
All work products, inventions, designs, and intellectual property created during employment belong exclusively to the Employer.

## 8. Non-Competition
**[If applicable: For a period of [Duration] after termination, Employee agrees not to engage in competing business within [Geographic Area]]**

## 9. Termination
This Agreement may be terminated:
- By either party with **[Notice Period]** written notice
- Immediately for cause (misconduct, breach of contract, etc.)
- **[Additional Termination Conditions]**

Upon termination, Employee must:
- Return all company property
- Complete transition duties as assigned
- Maintain confidentiality obligations

## 10. Dispute Resolution
Any disputes shall be resolved through **[Mediation/Arbitration/Court]** in accordance with **[Jurisdiction]** law.

## 11. Entire Agreement
This Agreement constitutes the entire agreement between the parties and supersedes all prior agreements.

## 12. Governing Law
This Agreement is governed by the laws of **[Jurisdiction]**.

## 13. Signatures

______________________  
**[Company Name]**  
By: **[Authorized Signatory Name]**  
Title: **[Title]**  
Date: **[Date]**

______________________  
**[Employee Full Name]**  
Employee  
Date: **[Date]**

---

**DISCLAIMER**: This document is a template for informational purposes only and does not constitute legal advice. Employment law varies significantly by jurisdiction. Please consult with a licensed attorney before using this agreement.
''';

  String _loanAgreementTemplate() => '''
# LOAN AGREEMENT

This Loan Agreement ("Agreement") is made on **[Date]** between:

**Lender:** **[Lender Name]**  
**Address:** **[Lender Address]**  
**ID/Registration:** **[Lender ID]**

**Borrower:** **[Borrower Name]**  
**Address:** **[Borrower Address]**  
**ID/Registration:** **[Borrower ID]**

## 1. Loan Amount
The Lender agrees to loan the Borrower the principal sum of **[Loan Amount]** (**[Amount in Words]**).

## 2. Purpose
The loan shall be used for: **[Loan Purpose]**

## 3. Disbursement
The loan shall be disbursed on **[Disbursement Date]** by **[Disbursement Method]**.

## 4. Interest Rate
Interest shall accrue at the rate of **[Interest Rate]%** per **[annum/month]**.

Interest calculation method: **[Simple/Compound]**

## 5. Repayment Terms
**Total Amount to be Repaid:** **[Total Amount]**

**Repayment Schedule:**
- Amount per installment: **[Installment Amount]**
- Payment frequency: **[Weekly/Bi-weekly/Monthly]**
- Number of payments: **[Number of Installments]**
- First payment due: **[First Payment Date]**
- Final payment due: **[Final Payment Date]**

**Payment Method:** **[Payment Method]**

## 6. Prepayment
The Borrower **[may/may not]** prepay the loan without penalty.

**[If prepayment penalty applies: Prepayment penalty of [Penalty Amount/Percentage]]**

## 7. Late Payment
Late payments will incur:
- Late fee of **[Late Fee Amount]**
- Additional interest of **[Penalty Interest Rate]%**
- Grace period: **[Grace Period Days]** days

## 8. Collateral
**[If secured loan:]**
This loan is secured by the following collateral:
- **[Collateral Description]**
- **[Collateral Value]**
- **[Collateral Location]**

**[If unsecured: This is an unsecured loan with no collateral.]**

## 9. Default
The loan shall be considered in default if:
- Payment is **[Days]** days overdue
- Borrower declares bankruptcy
- Borrower breaches any term of this Agreement
- **[Additional Default Conditions]**

## 10. Remedies Upon Default
Upon default, the Lender may:
- Declare the entire loan balance immediately due
- Charge default interest rate of **[Default Rate]%**
- **[If secured: Seize and sell collateral]**
- Pursue legal action for collection
- **[Additional Remedies]**

## 11. Governing Law
This Agreement is governed by the laws of **[Jurisdiction]**.

## 12. Entire Agreement
This Agreement constitutes the entire agreement between the parties regarding this loan.

## 13. Signatures

______________________  
**[Lender Name]**  
Lender  
Date: **[Date]**

______________________  
**[Borrower Name]**  
Borrower  
Date: **[Date]**

## Witness/Notary (if required)

______________________  
Witness Name: **[Witness Name]**  
Date: **[Date]**

---

**DISCLAIMER**: This document is a template for informational purposes only and does not constitute legal advice. Loan agreements may be subject to specific regulations in your jurisdiction. Please consult with a licensed attorney before using this agreement.
''';

  String _poaTemplate() => '''
# POWER OF ATTORNEY (POA)

This Power of Attorney is granted on **[Date]**.

## Principal Information
I, **[Principal Full Name]**, of **[Principal Address]**, ID Number **[Principal ID]**, being of sound mind, hereby appoint:

## Agent/Attorney-in-Fact Information
**[Agent Full Name]**  
**Address:** **[Agent Address]**  
**ID Number:** **[Agent ID]**  
**Relationship:** **[Relationship to Principal]**

as my true and lawful Attorney-in-Fact ("Agent") to act on my behalf.

## 1. Grant of Authority
The Agent is hereby authorized to act on my behalf in the following matters:

### Financial Matters
- Manage bank accounts and financial transactions
- Pay bills and expenses
- File tax returns
- Manage investments and securities
- Buy, sell, or lease property
- **[Additional Financial Powers]**

### Legal Matters
- Sign legal documents
- Enter into contracts
- Initiate or defend legal proceedings
- **[Additional Legal Powers]**

### Healthcare Decisions (if applicable)
- **[Healthcare powers if Medical POA]**

### Property Management
- Maintain, repair, and manage real property
- Collect rents and income
- **[Additional Property Powers]**

### Other Powers
- **[Specific Additional Powers]**

## 2. Limitations and Restrictions
The Agent may NOT:
- Create, modify, or revoke my will
- Make gifts on my behalf except **[Gift Limitations]**
- Change beneficiary designations on insurance or retirement accounts
- **[Additional Restrictions]**

## 3. Type of Power of Attorney
This is a **[General/Limited/Durable/Springing]** Power of Attorney.

**[If Durable: This Power of Attorney shall remain in effect if I become incapacitated.]**

**[If Springing: This Power of Attorney shall become effective only upon [Triggering Event].]**

## 4. Duration
This Power of Attorney shall:
- Begin on: **[Start Date]**
- **[Remain in effect until revoked / End on [End Date]]**

## 5. Revocation
I reserve the right to revoke this Power of Attorney at any time by providing written notice to my Agent.

## 6. Third Party Reliance
Any third party who receives a copy of this document may rely upon it as if it were an original.

## 7. Agent's Acceptance
By signing below, the Agent accepts this appointment and agrees to:
- Act in the Principal's best interest
- Keep accurate records of all transactions
- Keep the Principal's assets separate from Agent's own
- Avoid conflicts of interest

## 8. Compensation
The Agent shall **[receive/not receive]** compensation for services rendered.

**[If compensated: Compensation of [Amount/Rate]]**

## 9. Successor Agent
If **[Agent Name]** is unable or unwilling to serve, I appoint **[Successor Agent Name]** of **[Successor Agent Address]** as successor Agent.

## 10. Governing Law
This Power of Attorney is governed by the laws of **[Jurisdiction]**.

## 11. Signatures

### Principal's Signature

I have read this Power of Attorney and understand its contents. I am of sound mind and acting of my own free will.

______________________  
**[Principal Full Name]**  
Principal  
Date: **[Date]**

### Agent's Acceptance

I accept this appointment as Attorney-in-Fact and agree to act in the Principal's best interest.

______________________  
**[Agent Full Name]**  
Agent/Attorney-in-Fact  
Date: **[Date]**

## Witness Attestation

We, the undersigned witnesses, declare that the Principal signed this Power of Attorney in our presence and appeared to be of sound mind and acting voluntarily.

______________________  
**[Witness 1 Name]**  
Address: **[Witness 1 Address]**  
Date: **[Date]**

______________________  
**[Witness 2 Name]**  
Address: **[Witness 2 Address]**  
Date: **[Date]**

## Notary Acknowledgment (if required)

State of **[State]**  
County of **[County]**

On **[Date]**, before me personally appeared **[Principal Name]**, known to me to be the person described in and who executed the foregoing instrument, and acknowledged that they executed the same as their free act and deed.

______________________  
Notary Public  
My Commission Expires: **[Date]**

---

**DISCLAIMER**: This document is a template for informational purposes only and does not constitute legal advice. Power of Attorney documents have specific legal requirements that vary by jurisdiction. Some jurisdictions require notarization or specific witness requirements. Please consult with a licensed attorney before using this document.
''';
}