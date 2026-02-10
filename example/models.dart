class StarwarsResponse {
  StarwarsResponse({
    required this.character,
    required this.age,
  });

  String character;
  int age;

  factory StarwarsResponse.fromJson(Map<String, dynamic> json) =>
      StarwarsResponse(
        character: json['character'] as String,
        age: json['age'] as int,
      );

  Map<String, dynamic> toJson() => {
        'character': character,
        'age': age,
      };
}
