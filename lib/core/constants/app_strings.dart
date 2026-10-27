/// All user-facing Arabic strings strictly centralized for easy i18n/localization.
class AppStrings {
  // Brand
  static const String appName = 'MY GYM';
  static const String appTagline = 'قوة • انضباط • استمرار';
  static const String gymSlogan = 'قوة • انضباط • استمرار';
  static const String splashLoading = 'جاري التحميل...';

  // Greetings
  static const String greetingMorning = 'صباح القوة والنشاط، كابتن';
  static const String greetingEvening = 'مساء النشاط، كابتن';

  // Navigation Tabs
  static const String navHome = 'الرئيسية';
  static const String navMembers = 'الأعضاء';
  static const String navCheckIn = 'تسجيل حضور';
  static const String navAlerts = 'التنبيهات';

  // Common Actions
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String confirm = 'تأكيد';
  static const String search = 'بحث...';
  static const String filter = 'تصفية';
  static const String details = 'التفاصيل';
  static const String all = 'الكل';
  static const String undo = 'تراجع';
  static const String currency = 'ج.م';
  static const String daysLeft = 'يوم متبقي';
  static const String resetToDefault = 'استعادة النص الأصلي';

  // Auth & Onboarding
  static const String loginTitle = 'تسجيل الدخول';
  static const String loginWelcome = 'أهلاً بك مجدداً';
  static const String loginSubtitle = 'أدخل اسم المستخدم وكلمة المرور للوصول لإدارة الجيم';
  static const String setupOwnerTitle = 'إنشاء حساب المسؤول';
  static const String setupOwnerSubtitle = 'قم بإنشاء حسابك لإدارة الصالة الرياضية بأمان';
  static const String username = 'اسم المستخدم';
  static const String usernameHint = 'أدخل اسم المستخدم';
  static const String password = 'كلمة المرور';
  static const String passwordHint = 'أدخل كلمة المرور';
  static const String confirmPassword = 'تأكيد كلمة المرور';
  static const String confirmPasswordHint = 'أعد كتابة كلمة المرور';
  static const String createAccount = 'إنشاء الحساب';
  static const String authFooter = 'نظام إدارة الجيم • غير متصل بالإنترنت 100%';
  static const String signIn = 'تسجيل الدخول';
  static const String signInWithBiometrics = 'الدخول ببصمة الإصبع';
  static const String createOwnerAccount = 'إنشاء حساب المسؤول (أول تشغيل)';
  static const String ownerAccountCreated = 'تم إنشاء حساب المسؤول بنجاح';
  static const String invalidCredentials = 'اسم المستخدم أو كلمة المرور غير صحيحة';
  static const String passwordsDoNotMatch = 'كلمتا المرور غير متطابقتين';
  static const String passwordMismatch = 'كلمتا المرور غير متطابقتين';
  static const String passwordTooShort = 'كلمة المرور يجب ألا تقل عن 4 أحرف أو أرقام';
  static const String fieldRequired = 'هذا الحقل مطلوب';

  // Admin Management
  static const String adminSectionTitle = 'إدارة المسؤولين والكباتن';
  static const String addAdmin = 'إضافة مسؤول جديد';
  static const String adminDisplayName = 'الاسم الظاهر (مثال: كابتن أحمد)';
  static const String verifyCurrentAdmin = 'لتأكيد الهوية: أدخل بياناتك الحالية أولاً';
  static const String adminAddedSuccess = 'تمت إضافة المسؤول الجديد بنجاح';
  static const String invalidAdminCredentials = 'اسم المستخدم أو كلمة المرور الحالية غير صحيحة';
  static const String deleteAdminConfirm = 'هل تريد حذف هذا المسؤول؟';
  static const String cantDeleteSelf = 'لا يمكنك حذف الحساب المسجل به حالياً';
  static const String adminDeletedSuccess = 'تم حذف المسؤول بنجاح';

  // Home Dashboard
  static const String liveSummary = 'ملخص الصالة الرياضية';
  static const String activeMembers = 'الأعضاء النشطون';
  static const String expiringSoon = 'ينتهي قريباً';
  static const String expiredOverdue = 'منتهي الصلاحية';
  static const String todayCheckIns = 'حضور اليوم';
  static const String revenueTitle = 'إيرادات هذا الشهر';
  static const String revenueDetails = 'تفاصيل التقرير';
  static const String collectedThisMonth = 'المحصل فعلياً';
  static const String expectedThisMonth = 'المتوقع تحصيله';
  static const String outstanding = 'المتأخرات المعلقة';
  static const String outstandingAmount = 'المتأخرات المعلقة';
  static const String quickActions = 'إجراءات سريعة';
  static const String quickAddMember = 'إضافة عضو جديد';
  static const String quickCheckIn = 'تسجيل حضور سريع';
  static const String quickAlerts = 'متابعة التنبيهات';

  // Members List & Management
  static const String membersTitle = 'قائمة الأعضاء';
  static const String searchMembersHint = 'بحث بالاسم، رقم الهاتف، أو رقم العضو...';
  static const String searchHint = 'بحث بالاسم، رقم الهاتف، أو رقم العضو...';
  static const String filterAll = 'الكل';
  static const String filterActive = 'نشط';
  static const String filterExpiring = 'ينتهي قريباً';
  static const String filterExpired = 'منتهي';
  static const String filterUnpaid = 'غير مسدد';
  static const String paid = 'مدفوع بالكامل';
  static const String unpaid = 'غير مسدد';
  static const String noMembersFound = 'لم يتم العثور على أي مشتركين';
  static const String noMembersHint = 'اضغط على زر الإضافة لتسجيل أول مشترك في الجيم.';
  static const String addMemberPrompt = 'اضغط على زر الإضافة لتسجيل أول مشترك في الجيم.';

  // Add / Edit Member
  static const String addMemberTitle = 'إضافة مشترك جديد';
  static const String editMemberTitle = 'تعديل بيانات المشترك';
  static const String fullName = 'الاسم بالكامل';
  static const String fullNameHint = 'مثال: محمد أحمد';
  static const String phoneNumber = 'رقم الهاتف (11 رقم)';
  static const String phoneNumberHint = '01xxxxxxxxx';
  static const String startDate = 'تاريخ بداية الاشتراك';
  static const String plan = 'باقة الاشتراك';
  static const String selectPlan = 'اختر الباقة';
  static const String paidToggle = 'تم الدفع بالكامل';
  static const String amountPaid = 'المبلغ المدفوع';
  static const String amountPaidHint = 'أدخل المبلغ المسدد';
  static const String calculatedEndDate = 'تاريخ الانتهاء المحسوب:';
  static const String autoGeneratedId = 'رقم العضو:';
  static const String notes = 'ملاحظات إضافية (اختياري)';
  static const String notesHint = 'أي حالات خاصة أو توجيهات تدريبية...';
  static const String saveMember = 'حفظ العضو';
  static const String saveSuccess = 'تم حفظ العضو بنجاح';
  static const String duplicatePhoneWarning = 'تحذير: هذا الرقم مسجل بالفعل لعضو آخر. هل ترغب في المتابعة؟';

  // Member Details
  static const String memberDetails = 'ملف العضو';
  static const String currentSubscription = 'الاشتراك الحالي';
  static const String subscriptionHistory = 'سجل الاشتراكات';
  static const String attendanceHistory = 'سجل الحضور';
  static const String paymentHistory = 'سجل المدفوعات';
  static const String renewSubscription = 'تجديد الاشتراك';
  static const String callMember = 'اتصال بالعضو';
  static const String sendWhatsApp = 'إرسال واتساب';
  static const String totalVisits = 'إجمالي الزيارات';
  static const String lastVisit = 'آخر زيارة';
  static const String noVisitsYet = 'لا يوجد حضور مسجل بعد';
  static const String confirmDeleteMember = 'حذف هذا العضو؟';
  static const String deleteMemberWarning = 'سيؤدي حذف هذا العضو إلى مسح كامل سجل حضوره ومدفوعاته بشكل دائم.';
  static const String memberDeleted = 'تم حذف العضو بنجاح';

  // Renew Dialog
  static const String renewTitle = 'تجديد الاشتراك';
  static const String renewStartDate = 'تاريخ بدء التجديد';
  static const String autoRenewalNote = 'يبدأ التجديد تلقائياً بعد انتهاء الاشتراك السابق، أو من اليوم إذا كان منتهياً.';

  // Check-In Screen
  static const String checkInTitle = 'تسجيل الحضور الفوري';
  static const String checkInHint = 'أدخل رقم العضو أو ابحث بالاسم...';
  static const String memberIdField = 'رقم العضو';
  static const String submitCheckIn = 'تسجيل الحضور';
  static const String checkInSuccess = 'تم تسجيل الحضور بنجاح ✓';
  static const String checkInWarningExpiring = 'تم التسجيل ✓ (تنبيه: الاشتراك ينتهي قريباً!)';
  static const String checkInWarningUnpaid = 'تم التسجيل ✓ (تنبيه: عليه مبلغ متبقي غير مسدد!)';
  static const String checkInErrorExpired = 'عفواً! اشتراك العضو منتهي الصلاحية';
  static const String checkInErrorNotFound = 'لم يتم العثور على عضو بهذا الرقم';
  static const String checkInAlreadyToday = 'تم تسجيل حضور هذا العضو مسبقاً اليوم';
  static const String todayCheckInsList = 'حضور اليوم في الصالة';
  static const String noCheckInsToday = 'لم يسجل أي عضو حضوره اليوم بعد';

  // Alerts Screen
  static const String alertsTitle = 'التنبيهات والمتابعة';
  static const String tabExpiringSoon = 'ينتهي قريباً';
  static const String tabExpired = 'منتهية';
  static const String tabAbsent = 'غائبون';
  static const String absentDays = 'غائب منذ';
  static const String sendReminderWhatsApp = 'مراسلة واتساب';
  static const String quickRenew = 'تجديد فوري';
  static const String noAlerts = 'ممتاز! لا توجد تنبيهات معلقة';

  // Reports
  static const String reportsTitle = 'التقارير المالية والتشغيلية';
  static const String monthSelector = 'الشهر المالي';
  static const String newMembersCount = 'أعضاء جدد';
  static const String renewalsCount = 'تجديدات';
  static const String expiredSubscriptionsCount = 'اشتراكات انتهت';
  static const String monthlyRevenueBarChart = 'مقارنة التحصيل الشهري';
  static const String planDistribution = 'توزيع المشتركين حسب الباقات';
  static const String financialSummary = 'ملخص الحركات المالية';

  // Plans Management
  static const String plansTitle = 'إدارة باقات الاشتراك';
  static const String addPlan = 'إضافة باقة جديدة';
  static const String editPlan = 'تعديل الباقة';
  static const String planName = 'اسم الباقة';
  static const String planNameHint = 'مثال: اشتراك شهر، 3 شهور، سنوي';
  static const String planDurationMonths = 'المدة بالشهور';
  static const String planDurationDays = 'المدة بالأيام (اختياري)';
  static const String planPrice = 'السعر (ج.م)';
  static const String planPriceHint = 'مثال: 350';
  static const String planStatus = 'الحالة';
  static const String activePlan = 'متاحة للاشتراك';
  static const String inactivePlan = 'معطلة';
  static const String confirmDeletePlan = 'حذف الباقة؟';

  // Settings Screen
  static const String settingsTitle = 'إعدادات النظام والنسخ';
  static const String generalSettings = 'الإعدادات العامة';
  static const String warningDaysBeforeExpiry = 'أيام التنبيه قبل انتهاء الاشتراك';
  static const String absenceThresholdDays = 'حد اعتبار العضو غائباً (أيام)';
  static const String days = 'أيام';
  static const String templatesTitle = 'قوالب رسائل الواتساب التلقائية';
  static const String templateExpiryPrompt = 'تذكير بقرب انتهاء الاشتراك';
  static const String templateOverduePrompt = 'تنبيه الاشتراك المنتهي ومستحقات التجديد';
  static const String templateAbsentPrompt = 'رسالة متابعة غياب العضو';
  static const String templateHelp = 'المتغيرات المتاحة: {name}، {end_date}، {days_left}، {amount}، {gym}';

  // Backup & Restore
  static const String backupSection = 'النسخ الاحتياطي والأمان';
  static const String exportBackupJson = 'تصدير نسخة احتياطية كاملة (JSON)';
  static const String exportMembersCsv = 'تصدير بيانات الأعضاء (CSV)';
  static const String importBackupJson = 'استعادة نسخة احتياطية (JSON)';
  static const String backupSuccess = 'تم تصدير النسخة الاحتياطية بنجاح';
  static const String restoreSuccess = 'تمت استعادة البيانات بنجاح';
  static const String restoreConfirmTitle = 'تأكيد استعادة النسخة الاحتياطية';
  static const String restoreConfirmBody = 'تحذير: سيتم استبدال جميع البيانات الحالية بالبيانات الموجودة في ملف النسخة. هل أنت متأكد؟';
  static const String restoreInvalidFile = 'الملف المحدد غير صالح أو تالف';
  static const String backupReminderWarning = 'تنبيه: مر أكثر من 7 أيام منذ آخر نسخة احتياطية. ننصحك بحفظ نسخة الآن لحماية بياناتك!';
  static const String lastBackupDate = 'آخر نسخة احتياطية:';
  static const String neverBackedUp = 'لم يتم عمل نسخة بعد';

  // Security Settings
  static const String securitySection = 'الحماية وتسجيل الدخول';
  static const String changePassword = 'تغيير كلمة المرور';
  static const String currentPassword = 'كلمة المرور الحالية';
  static const String newPassword = 'كلمة المرور الجديدة';
  static const String enableBiometrics = 'تفعيل البصمة لتسجيل الدخول الفوري';
  static const String dailyReminder = 'إرسال إشعارات وتنبيهات يومية';
  static const String testNotification = 'إرسال إشعار تجريبي الآن';
  static const String testNotificationSent = 'تم إرسال الإشعار بنجاح';
  static const String passwordChangedSuccess = 'تم تغيير كلمة المرور بنجاح';

  // Professional Egyptian Arabic Templates
  static const String defaultExpiryTemplate =
      'السلام عليكم يا كابتن {name} 🌹، نحب نفكرك إن اشتراكك في {gym} باقي عليه {days_left} يوم وينتهي في {end_date}. في انتظارك لتجديد الاشتراك ومواصلة تمرينك وأهدافك 💪🔥';

  static const String defaultOverdueTemplate =
      'أهلاً كابتن {name} 🌟، نود إحاطتك بأن اشتراكك في {gym} قد انتهى بتاريخ {end_date} (المبلغ المطلوب للتجديد: {amount} ج.م). مستنينك تنورنا في الجيم لتجديد اشتراكك ونكمل تدريبنا مع بعض! 🏋️‍♂️';

  static const String defaultAbsentTemplate =
      'وحشتنا في الجيم يا كابتن {name} 🤍! لاحظنا غيابك بقالك كذا يوم، وحابين نطمن عليك. الرياضة أسلوب حياة ودايماً مكانك محجوز في {gym}.. مستنينك في أقرب وقت ترجع أقوى! 💥';

  static const String defaultPaymentReminderTemplate =
      'أهلاً كابتن {name} 🌸، تذكير ودي بوجود مبلغ متبقي قدره {amount} ج.م على اشتراكك في {gym}. شكراً لتعاونك ودمت في كامل الصحة والقوة!';
}
