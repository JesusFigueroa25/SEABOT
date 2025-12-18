class HelpResource {
  final String nameResource;
  final bool enable;
  final int id;
  //Nuevas columnas
  final String? description;
  final String? resourceType;
  final String? url;

  HelpResource({
    required this.nameResource,
    required this.enable,
    required this.id,
    this.description,
    this.resourceType,
    this.url,
  });
  //toma un JSON y conviértelo en un objeto Dart.
  //Puedo crear varios factorys para manejar diferentes tipos de JSON
  factory HelpResource.fromJson(Map<String, dynamic> json) {
    return HelpResource(
      id: json['id'],
      nameResource: json['name_resource'],
      description: json['description'],
      resourceType: json['resource_type'],
      url: json['url'],
      enable: json['enable'] ?? true,
    );
  }
  //Esto sirve cuando quieras guardar o enviar datos al servidor.
  Map<String, dynamic> toJson() {
    return {'name_resource': nameResource, 'enable': enable};
  }
}
