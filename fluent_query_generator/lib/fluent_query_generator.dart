import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/fluent_model_generator.dart';
import 'src/fluent_query_generator.dart';

Builder fluent_query(BuilderOptions options) => SharedPartBuilder([
      FluentModelGenerator(),
      FluentQueryGenerator(),
    ], 'fluent_query');
