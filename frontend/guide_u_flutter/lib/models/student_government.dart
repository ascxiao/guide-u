class StudentGovernmentMember {
  final String name;
  final String position;
  final String group;

  StudentGovernmentMember({
    required this.name,
    required this.position,
    required this.group,
  });
}

class StudentGovernmentGroup {
  final String title;
  final List<StudentGovernmentMember> members;

  StudentGovernmentGroup({required this.title, required this.members});
}

final List<StudentGovernmentGroup> studentGovernmentGroups = [
  StudentGovernmentGroup(
    title: 'Executive Branch',
    members: [
      StudentGovernmentMember(
        name: 'Ken Paolo G. Gilo',
        position: 'President',
        group: 'Executive',
      ),
      StudentGovernmentMember(
        name: 'Mitchel G. Mariano',
        position: 'Vice President',
        group: 'Executive',
      ),
      StudentGovernmentMember(
        name: 'Angela Grace Diamartin',
        position: 'Treasurer',
        group: 'Executive',
      ),
      StudentGovernmentMember(
        name: 'Ashley Nicole L. Torrefranca',
        position: 'Secretary',
        group: 'Executive',
      ),
      // ... add all other executive members here
    ],
  ),
  StudentGovernmentGroup(
    title: 'Legislative Branch',
    members: [
      StudentGovernmentMember(
        name: 'Genivie Joy Magsico',
        position: 'Senate President',
        group: 'Legislative',
      ),
      StudentGovernmentMember(
        name: 'Kyla Medel',
        position: 'Senate President Pro-Tempore',
        group: 'Legislative',
      ),
      // ... add all other legislative members here
    ],
  ),
  StudentGovernmentGroup(
    title: 'Judiciary Branch',
    members: [
      StudentGovernmentMember(
        name: 'Franz Juls Abram Alojado',
        position: 'Chief Judge',
        group: 'Judiciary',
      ),
      // ... add all other judiciary members here
    ],
  ),
  StudentGovernmentGroup(
    title: 'Commission on Audit',
    members: [
      StudentGovernmentMember(
        name: 'Betty Mae De La Banda',
        position: 'Chairperson',
        group: 'Audit',
      ),
      // ... add all other audit members here
    ],
  ),
  StudentGovernmentGroup(
    title: 'Commission on Elections',
    members: [
      StudentGovernmentMember(
        name: 'Albert Valente',
        position: 'Chairperson',
        group: 'Elections',
      ),
      // ... add all other election members here
    ],
  ),
  StudentGovernmentGroup(
    title: 'College Student Councils',
    members: [
      StudentGovernmentMember(
        name: 'Ever Joyce Magdalera',
        position: 'Governor, College of Arts and Sciences',
        group: 'College Councils',
      ),
      StudentGovernmentMember(
        name: 'Denisse Gaille Leonoras',
        position: 'Governor, College of Education',
        group: 'College Councils',
      ),
      StudentGovernmentMember(
        name: 'Christian Esrael Sian',
        position: 'Governor, College of Engineering and Technology',
        group: 'College Councils',
      ),
      StudentGovernmentMember(
        name: 'Patricia Ann Gonzaga',
        position: 'Governor, College of Nursing',
        group: 'College Councils',
      ),
      StudentGovernmentMember(
        name: 'Brian Paul Mesada',
        position: 'Governor, Yu An Log College of Business and Accountancy',
        group: 'College Councils',
      ),
      // ... add all other council members here
    ],
  ),
];
