import 'package:codewalk/data/models/chat_realtime_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatEventModel', () {
    test('preserves authoritative global envelope metadata', () {
      final payloadProperties = <String, dynamic>{
        'sessionID': 'ses_1',
        'directory': '/payload/directory',
        'project': 'payload-project',
        'workspace': 'payload-workspace',
      };

      final model = ChatEventModel.fromJson(<String, dynamic>{
        'directory': '/outer/directory',
        'project': 'outer-project',
        'workspace': 'outer-workspace',
        'payload': <String, dynamic>{
          'id': 'evt_1',
          'type': 'session.updated',
          'properties': payloadProperties,
        },
      });

      expect(model.type, 'session.updated');
      expect(model.properties['sessionID'], 'ses_1');
      expect(model.properties['directory'], '/outer/directory');
      expect(model.properties['project'], 'outer-project');
      expect(model.properties['workspace'], 'outer-workspace');
      expect(payloadProperties['directory'], '/payload/directory');
      expect(payloadProperties['project'], 'payload-project');
      expect(payloadProperties['workspace'], 'payload-workspace');
    });

    test('does not synthesize missing global context metadata', () {
      final model = ChatEventModel.fromJson(<String, dynamic>{
        'payload': <String, dynamic>{
          'id': 'evt_connected',
          'type': 'server.connected',
          'properties': <String, dynamic>{},
        },
      });

      expect(model.type, 'server.connected');
      expect(model.properties, isEmpty);
      expect(model.properties.containsKey('directory'), isFalse);
      expect(model.properties.containsKey('project'), isFalse);
      expect(model.properties.containsKey('workspace'), isFalse);
    });

    test('keeps flat event parsing and copies properties', () {
      final properties = <String, dynamic>{'sessionID': 'ses_flat'};
      final model = ChatEventModel.fromJson(<String, dynamic>{
        'type': 'session.status',
        'properties': properties,
      });

      properties['sessionID'] = 'mutated';

      expect(model.type, 'session.status');
      expect(model.properties, <String, dynamic>{'sessionID': 'ses_flat'});
    });
  });
}
