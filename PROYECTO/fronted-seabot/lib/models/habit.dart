class Habit {
  final int habitId;
  final String nameHabit;
  final String? description;
  final String? iconHabit;
  final String fecha;
  bool completed;

  Habit({
    required this.habitId,
    required this.nameHabit,
    this.description,
    this.iconHabit,
    required this.fecha,
    required this.completed,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      habitId: json['habit_id'],
      nameHabit: json['name_habit'],
      description: json['description'],
      iconHabit: json['icon_habit'],
      fecha: json['fecha'],
      completed: json['completed'],
    );
  }

  Map<String, dynamic> toToggleJson(int studentId) {
    return {
      "habit_id": habitId,
      "student_id": studentId,
      "completed": completed,
    };
  }
}