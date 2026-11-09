import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ALU email check', () {
    test('accepts ALU student and staff domains', () {
      expect(Validators.isAluEmail('a.student@alustudent.com'), isTrue);
      expect(Validators.isAluEmail('staff.member@alueducation.com'), isTrue);
    });

    test('ignores case and surrounding spaces', () {
      expect(Validators.isAluEmail('  A.Student@ALUSTUDENT.com '), isTrue);
    });

    test('rejects other domains and look-alikes', () {
      expect(Validators.isAluEmail('someone@gmail.com'), isFalse);
      expect(Validators.isAluEmail('someone@alustudent.com.evil.com'), isFalse);
      expect(Validators.isAluEmail('someone@fakealustudent.com'), isFalse);
    });
  });

  group('Form validators', () {
    test('email validator explains why an email is rejected', () {
      expect(Validators.email(''), 'Please enter your email');
      expect(Validators.email('not-an-email'), 'Enter a valid email address');
      expect(Validators.email('x@gmail.com'), contains('ALU email'));
      expect(Validators.email('x@alustudent.com'), isNull);
    });

    test('new password needs 8+ characters and a number', () {
      expect(Validators.newPassword('short1'), isNotNull);
      expect(Validators.newPassword('longpassword'), isNotNull);
      expect(Validators.newPassword('longpassword1'), isNull);
    });

    test('confirm password must match', () {
      expect(Validators.confirmPassword('abc12345', 'abc12346'), 'Passwords do not match');
      expect(Validators.confirmPassword('abc12345', 'abc12345'), isNull);
    });
  });

  group('UserRole', () {
    test('only "staff" grants the staff role', () {
      expect(UserRole.fromString('staff'), UserRole.staff);
      expect(UserRole.fromString('student'), UserRole.student);
      expect(UserRole.fromString('admin'), UserRole.student);
      expect(UserRole.fromString(null), UserRole.student);
    });
  });
}
