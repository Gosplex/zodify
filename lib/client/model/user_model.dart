enum UserType {
  user,
  astrologer,
  pendingAstrologer,
}

enum AstrologerStatus {
  none,
  pending,
  approved,
  rejected,
}

enum UserAction {
  typing,
  recording,
  none,
}

class UserModel {
  final String? id;
  final String? phoneNumber;
  final String? email;
  final String? name;
  final String? userProfile;
  final String? fcmToken;
  final List<String>? languages;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastActive;
  final String? currentAppVersion;
  final double? walletBalance;
  final bool? isOnline;
  final UserAction? currentAction;

  // Basic user details
  final String? gender;
  final String? birthDate;
  final bool? knowsBirthTime;
  final String? birthTime;
  final String? birthPlace;

  // Role management
  final UserType? userType;
  final AstrologerProfile? astrologerProfile;
  final String? lastDashboardLoggedIn;

  UserModel({
    this.id,
    this.phoneNumber,
    this.email,
    this.name,
    this.userProfile,
    this.fcmToken,
    this.languages,
    this.createdAt,
    this.updatedAt,
    this.lastActive,
    this.currentAppVersion,
    this.walletBalance,
    this.isOnline,
    this.currentAction = UserAction.none,
    this.gender,
    this.birthDate,
    this.knowsBirthTime,
    this.birthTime,
    this.birthPlace,
    this.userType = UserType.user,
    this.astrologerProfile,
    this.lastDashboardLoggedIn,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      name: json['name'],
      userProfile: json['userProfile']??json['imageUrl']??"https://as2.ftcdn.net/jpg/02/75/60/35/1000_F_275603548_VIAKu1fpkujDwrCrXox5RWWjW7SeBkdX.jpg",
      fcmToken: json['fcmToken'],
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      lastActive: json['lastActive'] != null ? DateTime.parse(json['lastActive']) : null,
      currentAppVersion: json['currentAppVersion'],
      walletBalance: (json['walletBalance'] as num?)?.toDouble(),
      isOnline: json['isOnline'],
      currentAction: json['currentAction'] != null
          ? UserAction.values.firstWhere(
            (e) => e.toString().split('.').last == json['currentAction'],
        orElse: () => UserAction.none,
      )
          : null,
      gender: json['gender'],
      birthDate: json['birthDate'],
      knowsBirthTime: json['knowsBirthTime'],
      birthTime: json['birthTime'],
      birthPlace: json['birthPlace'],
      userType: json['userType'] != null
          ? UserType.values.firstWhere(
            (e) => e.toString().split('.').last == json['userType'],
        orElse: () => UserType.user,
      )
          : null,
      astrologerProfile: json['astrologerProfile'] != null
          ? AstrologerProfile.fromJson(json['astrologerProfile'])
          : null,
      lastDashboardLoggedIn: json['lastDashboardLoggedIn'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'email': email,
      'name': name,
      'userProfile': userProfile,
      'fcmToken': fcmToken,
      'languages': languages,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
      'currentAppVersion': currentAppVersion,
      'walletBalance': walletBalance,
      'isOnline': isOnline,
      'currentAction': currentAction?.toString().split('.').last,
      'gender': gender,
      'birthDate': birthDate,
      'knowsBirthTime': knowsBirthTime,
      'birthTime': birthTime,
      'birthPlace': birthPlace,
      'userType': userType?.toString().split('.').last,
      'astrologerProfile': astrologerProfile?.toJson(),
      'lastDashboardLoggedIn': lastDashboardLoggedIn,
    };
  }

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? email,
    String? name,
    String? userProfile,
    String? fcmToken,
    List<String>? languages,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActive,
    String? currentAppVersion,
    double? walletBalance,
    bool? isOnline,
    UserAction? currentAction,
    String? gender,
    String? birthDate,
    bool? knowsBirthTime,
    String? birthTime,
    String? birthPlace,
    UserType? userType,
    AstrologerProfile? astrologerProfile,
    String? lastDashboardLoggedIn,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      name: name ?? this.name,
      userProfile: userProfile ?? this.userProfile,
      fcmToken: fcmToken ?? this.fcmToken,
      languages: languages ?? this.languages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActive: lastActive ?? this.lastActive,
      currentAppVersion: currentAppVersion ?? this.currentAppVersion,
      walletBalance: walletBalance ?? this.walletBalance,
      isOnline: isOnline ?? this.isOnline,
      currentAction: currentAction ?? this.currentAction,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      knowsBirthTime: knowsBirthTime ?? this.knowsBirthTime,
      birthTime: birthTime ?? this.birthTime,
      birthPlace: birthPlace ?? this.birthPlace,
      userType: userType ?? this.userType,
      astrologerProfile: astrologerProfile ?? this.astrologerProfile,
      lastDashboardLoggedIn: lastDashboardLoggedIn ?? this.lastDashboardLoggedIn,
    );
  }
}

class AstrologerProfile {
  final String? name;
  final String? email;
  final String? gender;
  final String? birthDate;
  final List<String>? languages;
  final String? bio;
  final String? specialization;
  final List<String>? skills;
  final double? rating;
  final int? totalReadings;
  final int? yearsOfExperience;
  final String? certificationUrl;
  final String? idProofUrl;
  final String? imageUrl;
  final bool? isOnline;
  final AstrologerStatus? status;
  final DateTime? approvalDate;
  final String? rejectionReason;
  final Availability? availability;

  AstrologerProfile({
    this.name,
    this.availability,
    this.email,
    this.gender,
    this.birthDate,
    this.languages,
    this.bio,
    this.specialization,
    this.skills,
    this.rating = 0.0,
    this.totalReadings = 0,
    this.yearsOfExperience,
    this.certificationUrl,
    this.idProofUrl,
    this.isOnline,
    this.imageUrl,
    this.status = AstrologerStatus.none,
    this.approvalDate,
    this.rejectionReason,
  });

  factory AstrologerProfile.fromJson(Map<String, dynamic> json) {
    return AstrologerProfile(
      name: json['name'],
      email: json['email'],
      availability: json['availability']!=null?Availability.fromJson(json['availability']):null,
      gender: json['gender'],
      birthDate: json['birthDate'],
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList(),
      bio: json['bio'],
      isOnline: json['isOnline'],
      specialization: json['specialization'],
      skills: (json['skills'] as List?)?.map((e) => e.toString()).toList(),
      rating: (json['rating'] as num?)?.toDouble(),
      totalReadings: json['totalReadings'],
      yearsOfExperience: json['yearsOfExperience'],
      certificationUrl: json['certificationUrl'],
      idProofUrl: json['idProofUrl'],
      imageUrl: json['imageUrl'],
      status: json['status'] != null
          ? AstrologerStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
        orElse: () => AstrologerStatus.none,
      )
          : null,
      approvalDate: json['approvalDate'] != null
          ? DateTime.parse(json['approvalDate'])
          : null,
      rejectionReason: json['rejectionReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'availability': availability,
      'gender': gender,
      'birthDate': birthDate,
      'languages': languages,
      'bio': bio,
      'specialization': specialization,
      'skills': skills,
      'rating': rating,
      'totalReadings': totalReadings,
      'yearsOfExperience': yearsOfExperience,
      'certificationUrl': certificationUrl,
      'idProofUrl': idProofUrl,
      'imageUrl': imageUrl,
      'isOnline': isOnline,
      'status': status?.toString().split('.').last,
      'approvalDate': approvalDate?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  AstrologerProfile copyWith({
    String? name,
    String? email,
    String? gender,
    String? birthDate,
    List<String>? languages,
    String? bio,
    String? specialization,
    List<String>? skills,
    double? rating,
    int? totalReadings,
    int? yearsOfExperience,
    bool? isOnline,
    String? certificationUrl,
    String? idProofUrl,
    String? imageUrl,
    AstrologerStatus? status,
    DateTime? approvalDate,
    String? rejectionReason,
  }) {
    return AstrologerProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      languages: languages ?? this.languages,
      bio: bio ?? this.bio,
      specialization: specialization ?? this.specialization,
      skills: skills ?? this.skills,
      rating: rating ?? this.rating,
      totalReadings: totalReadings ?? this.totalReadings,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      certificationUrl: certificationUrl ?? this.certificationUrl,
      idProofUrl: idProofUrl ?? this.idProofUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      isOnline: isOnline ?? false,
      status: status ?? this.status,
      approvalDate: approvalDate ?? this.approvalDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

class Availability{
  bool available_for_call;
  bool available_for_chat;
  bool available_for_video;

  Availability({this.available_for_call=false,this.available_for_chat=false,this.available_for_video=false});

  factory Availability.fromJson(var data){
    return Availability(
      available_for_call: data['available_for_call'],
      available_for_chat: data['available_for_chat'],
      available_for_video: data['available_for_video'],
    );
  }

  Map toJson(){
    return {
      "available_for_call":available_for_call,
      "available_for_chat":available_for_chat,
      "available_for_video":available_for_video,
    };
  }
}