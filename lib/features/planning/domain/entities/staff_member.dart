class StaffMember {
  final int id;
  final String name;
  final String? grade;
  final String? group;
  final String team;
  final int order;

  const StaffMember({
    required this.id,
    required this.name,
    required this.team,
    this.grade,
    this.group,
    this.order = 0,
  });
}
