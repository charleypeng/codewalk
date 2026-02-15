import 'package:equatable/equatable.dart';

/// Technical comment translated to English.
class Provider extends Equatable {

  const Provider({
    required this.id,
    required this.name,
    required this.env,
    this.api,
    this.npm,
    required this.models,
  });
  final String id;
  final String name;
  final List<String> env;
  final String? api;
  final String? npm;
  final Map<String, Model> models;

  @override
  List<Object?> get props => [id, name, env, api, npm, models];
}

/// Technical comment translated to English.
class Model extends Equatable {

  const Model({
    required this.id,
    required this.name,
    required this.releaseDate,
    required this.attachment,
    required this.reasoning,
    required this.temperature,
    required this.toolCall,
    required this.cost,
    required this.limit,
    required this.options,
    this.variants = const <String, ModelVariant>{},
    this.knowledge,
    this.lastUpdated,
    this.modalities,
    this.openWeights,
  });
  final String id;
  final String name;
  final String releaseDate;
  final bool attachment;
  final bool reasoning;
  final bool temperature;
  final bool toolCall;
  final ModelCost cost;
  final ModelLimit limit;
  final Map<String, dynamic> options;
  final Map<String, ModelVariant> variants;
  final String? knowledge;
  final String? lastUpdated;
  final Map<String, dynamic>? modalities;
  final bool? openWeights;

  @override
  List<Object?> get props => [
    id,
    name,
    releaseDate,
    attachment,
    reasoning,
    temperature,
    toolCall,
    cost,
    limit,
    options,
    variants,
    knowledge,
    lastUpdated,
    modalities,
    openWeights,
  ];
}

/// Technical comment translated to English.
class ModelVariant extends Equatable {
  const ModelVariant({
    required this.id,
    required this.name,
    this.description,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String name;
  final String? description;
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props => [id, name, description, metadata];
}

/// Technical comment translated to English.
class ModelCost extends Equatable {

  const ModelCost({
    required this.input,
    required this.output,
    this.cacheRead,
    this.cacheWrite,
  });
  final double input;
  final double output;
  final double? cacheRead;
  final double? cacheWrite;

  @override
  List<Object?> get props => [input, output, cacheRead, cacheWrite];
}

/// Technical comment translated to English.
class ModelLimit extends Equatable {

  const ModelLimit({required this.context, required this.output});
  final int context;
  final int output;

  @override
  List<Object> get props => [context, output];
}

/// Technical comment translated to English.
class ProvidersResponse extends Equatable {

  const ProvidersResponse({
    required this.providers,
    required this.defaultModels,
    this.connected = const [],
  });
  final List<Provider> providers;
  final Map<String, String> defaultModels;
  final List<String> connected;

  @override
  List<Object> get props => [providers, defaultModels, connected];
}
