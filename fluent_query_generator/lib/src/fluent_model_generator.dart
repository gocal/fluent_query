import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';
import 'package:fluent_query/fluent_query.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

class FluentModelGenerator extends GeneratorForAnnotation<FluentModel> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (!(element is ClassElement)) {
      throw Exception(
        '@${annotation} anontation must be used on class element',
      );
    }

    final model = element as ClassElement;

    _assertClassValid(model);

    final className =
        annotation.peek('className')?.stringValue ?? model.displayName;

    final companionClassName = "${className}\$Model";

    final classBuilder = ClassBuilder()
      ..abstract = false
      ..name = companionClassName
      ..fields.addAll(model.fields.map((field) {
        final typeString = field.type.getDisplayString(withNullability: false);
        final displayName = field.displayName;
        final builder = FieldBuilder()
          ..name = displayName
          ..static = true
          ..modifier = FieldModifier.constant
          ..assignment = Code(
              "FluentProperty<$className, $typeString>(\"${displayName}\")");

        return builder.build();
      }));

    final stringBuilder = StringBuffer();
    final emitter = DartEmitter();

    stringBuilder.write(classBuilder.build().accept(emitter).toString());

    return DartFormatter().format(stringBuilder.toString());
  }

  void _assertClassValid(ClassElement element) {
    // abstract
    if (element.isAbstract) {
      throw InvalidGenerationSourceError(
          'The ${element.name} cannot be abstract');
    }

    if (element.fields.isEmpty) {
      throw InvalidGenerationSourceError('@$element.name must have parameters');
    }
  }
}
