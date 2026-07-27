class TeamStaffProjection {
  final String team;
  final List<String> staffIds;

  const TeamStaffProjection({
    required this.team,
    required this.staffIds,
  });

  bool containsStaff(String staffId) {
    return staffIds.contains(staffId);
  }
}
