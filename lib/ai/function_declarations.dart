// lib/ai/function_declarations.dart

import 'package:google_generative_ai/google_generative_ai.dart';

List<FunctionDeclaration> getFunctionDeclarations() {
  return [
    FunctionDeclaration(
      'open_bus_tracker',
      'Opens live bus tracking screen',
      Schema(SchemaType.object, properties: {}),
    ),
    FunctionDeclaration(
      'open_map',
      'Opens campus map for navigation',
      Schema(SchemaType.object, properties: {}),
    ),
    FunctionDeclaration(
      'open_notices',
      'Shows latest campus notices and announcements',
      Schema(SchemaType.object, properties: {}),
    ),
    FunctionDeclaration(
      'show_notice_detail',
      'Shows detailed information about a specific notice',
      Schema(SchemaType.object, properties: {
        'notice_id': Schema(SchemaType.string, description: 'Notice ID'),
      }),
    ),
    FunctionDeclaration(
      'open_hostels',
      'Shows hostel information and facilities',
      Schema(SchemaType.object, properties: {}),
    ),
    FunctionDeclaration(
      'open_library',
      'Opens library section with timings and info',
      Schema(SchemaType.object, properties: {}),
    ),
    FunctionDeclaration(
      'register_complaint',
      'Opens complaint registration form',
      Schema(SchemaType.object, properties: {}),
    ),
    FunctionDeclaration(
      'find_next_class',
      'Finds the next scheduled class based on branch and semester',
      Schema(SchemaType.object, properties: {
        'semester_group': Schema(SchemaType.string,
            description:
                'Semester Group (e.g., Diploma_Sem_VI, Degree_Sem_IV)'),
        'branch': Schema(SchemaType.string,
            description: 'Branch code (e.g., CSE, CE, ET, FP)'),
      }, requiredProperties: [
        'semester_group',
        'branch'
      ]),
    ),
  ];
}
