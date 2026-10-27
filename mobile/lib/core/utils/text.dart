/// "1 unit", "3 units". Pass [many] for irregular plurals.
String plural(int count, String one, [String? many]) =>
    '$count ${count == 1 ? one : (many ?? '${one}s')}';
