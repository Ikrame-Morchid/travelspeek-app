// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTranslationCollection on Isar {
  IsarCollection<Translation> get translations => this.collection();
}

const TranslationSchema = CollectionSchema(
  name: r'Translation',
  id: 2419298645870007561,
  properties: {
    r'audioDuration': PropertySchema(
      id: 0,
      name: r'audioDuration',
      type: IsarType.double,
    ),
    r'audioUrl': PropertySchema(
      id: 1,
      name: r'audioUrl',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'hasOffensiveContent': PropertySchema(
      id: 3,
      name: r'hasOffensiveContent',
      type: IsarType.bool,
    ),
    r'imageLocalPath': PropertySchema(
      id: 4,
      name: r'imageLocalPath',
      type: IsarType.string,
    ),
    r'imageUrl': PropertySchema(
      id: 5,
      name: r'imageUrl',
      type: IsarType.string,
    ),
    r'isFavorite': PropertySchema(
      id: 6,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'languagePair': PropertySchema(
      id: 7,
      name: r'languagePair',
      type: IsarType.string,
    ),
    r'shortText': PropertySchema(
      id: 8,
      name: r'shortText',
      type: IsarType.string,
    ),
    r'sourceLanguage': PropertySchema(
      id: 9,
      name: r'sourceLanguage',
      type: IsarType.string,
    ),
    r'sourceText': PropertySchema(
      id: 10,
      name: r'sourceText',
      type: IsarType.string,
    ),
    r'targetLanguage': PropertySchema(
      id: 11,
      name: r'targetLanguage',
      type: IsarType.string,
    ),
    r'translatedText': PropertySchema(
      id: 12,
      name: r'translatedText',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 13,
      name: r'type',
      type: IsarType.string,
      enumMap: _TranslationtypeEnumValueMap,
    ),
    r'typeIcon': PropertySchema(
      id: 14,
      name: r'typeIcon',
      type: IsarType.string,
    ),
    r'typeLabel': PropertySchema(
      id: 15,
      name: r'typeLabel',
      type: IsarType.string,
    )
  },
  estimateSize: _translationEstimateSize,
  serialize: _translationSerialize,
  deserialize: _translationDeserialize,
  deserializeProp: _translationDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _translationGetId,
  getLinks: _translationGetLinks,
  attach: _translationAttach,
  version: '3.1.0+1',
);

int _translationEstimateSize(
  Translation object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.audioUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.imageLocalPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.imageUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.languagePair.length * 3;
  bytesCount += 3 + object.shortText.length * 3;
  bytesCount += 3 + object.sourceLanguage.length * 3;
  bytesCount += 3 + object.sourceText.length * 3;
  bytesCount += 3 + object.targetLanguage.length * 3;
  bytesCount += 3 + object.translatedText.length * 3;
  bytesCount += 3 + object.type.name.length * 3;
  bytesCount += 3 + object.typeIcon.length * 3;
  bytesCount += 3 + object.typeLabel.length * 3;
  return bytesCount;
}

void _translationSerialize(
  Translation object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.audioDuration);
  writer.writeString(offsets[1], object.audioUrl);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeBool(offsets[3], object.hasOffensiveContent);
  writer.writeString(offsets[4], object.imageLocalPath);
  writer.writeString(offsets[5], object.imageUrl);
  writer.writeBool(offsets[6], object.isFavorite);
  writer.writeString(offsets[7], object.languagePair);
  writer.writeString(offsets[8], object.shortText);
  writer.writeString(offsets[9], object.sourceLanguage);
  writer.writeString(offsets[10], object.sourceText);
  writer.writeString(offsets[11], object.targetLanguage);
  writer.writeString(offsets[12], object.translatedText);
  writer.writeString(offsets[13], object.type.name);
  writer.writeString(offsets[14], object.typeIcon);
  writer.writeString(offsets[15], object.typeLabel);
}

Translation _translationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Translation(
    audioDuration: reader.readDoubleOrNull(offsets[0]),
    audioUrl: reader.readStringOrNull(offsets[1]),
    createdAt: reader.readDateTime(offsets[2]),
    hasOffensiveContent: reader.readBoolOrNull(offsets[3]) ?? false,
    id: id,
    imageLocalPath: reader.readStringOrNull(offsets[4]),
    imageUrl: reader.readStringOrNull(offsets[5]),
    isFavorite: reader.readBoolOrNull(offsets[6]) ?? false,
    sourceLanguage: reader.readString(offsets[9]),
    sourceText: reader.readString(offsets[10]),
    targetLanguage: reader.readString(offsets[11]),
    translatedText: reader.readString(offsets[12]),
    type: _TranslationtypeValueEnumMap[reader.readStringOrNull(offsets[13])] ??
        TranslationType.voice,
  );
  return object;
}

P _translationDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (_TranslationtypeValueEnumMap[reader.readStringOrNull(offset)] ??
          TranslationType.voice) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TranslationtypeEnumValueMap = {
  r'voice': r'voice',
  r'image': r'image',
  r'text': r'text',
};
const _TranslationtypeValueEnumMap = {
  r'voice': TranslationType.voice,
  r'image': TranslationType.image,
  r'text': TranslationType.text,
};

Id _translationGetId(Translation object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _translationGetLinks(Translation object) {
  return [];
}

void _translationAttach(
    IsarCollection<dynamic> col, Id id, Translation object) {
  object.id = id;
}

extension TranslationQueryWhereSort
    on QueryBuilder<Translation, Translation, QWhere> {
  QueryBuilder<Translation, Translation, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TranslationQueryWhere
    on QueryBuilder<Translation, Translation, QWhereClause> {
  QueryBuilder<Translation, Translation, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Translation, Translation, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Translation, Translation, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Translation, Translation, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TranslationQueryFilter
    on QueryBuilder<Translation, Translation, QFilterCondition> {
  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      audioDurationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'audioDuration',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      audioDurationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'audioDuration',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      audioDurationEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioDuration',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      audioDurationGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'audioDuration',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      audioDurationLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'audioDuration',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      audioDurationBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'audioDuration',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      audioUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'audioUrl',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      audioUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'audioUrl',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> audioUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      audioUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'audioUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      audioUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'audioUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> audioUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'audioUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      audioUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'audioUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      audioUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'audioUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      audioUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'audioUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> audioUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'audioUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      audioUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      audioUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'audioUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      hasOffensiveContentEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasOffensiveContent',
        value: value,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageLocalPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imageLocalPath',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageLocalPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imageLocalPath',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageLocalPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageLocalPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageLocalPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imageLocalPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageLocalPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imageLocalPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageLocalPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imageLocalPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageLocalPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imageLocalPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageLocalPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imageLocalPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageLocalPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imageLocalPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageLocalPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imageLocalPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageLocalPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageLocalPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageLocalPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imageLocalPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imageUrl',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imageUrl',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> imageUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> imageUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imageUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> imageUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imageUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      imageUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      isFavoriteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFavorite',
        value: value,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      languagePairEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'languagePair',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      languagePairGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'languagePair',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      languagePairLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'languagePair',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      languagePairBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'languagePair',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      languagePairStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'languagePair',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      languagePairEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'languagePair',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      languagePairContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'languagePair',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      languagePairMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'languagePair',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      languagePairIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'languagePair',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      languagePairIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'languagePair',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      shortTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shortText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      shortTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'shortText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      shortTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'shortText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      shortTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'shortText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      shortTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'shortText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      shortTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'shortText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      shortTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'shortText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      shortTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'shortText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      shortTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shortText',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      shortTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'shortText',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceLanguageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceLanguageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceLanguageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceLanguageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceLanguage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceLanguageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceLanguageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceLanguageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceLanguageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceLanguage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceLanguageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceLanguage',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceLanguageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceLanguage',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceText',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      sourceTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceText',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      targetLanguageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      targetLanguageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      targetLanguageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      targetLanguageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetLanguage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      targetLanguageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'targetLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      targetLanguageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'targetLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      targetLanguageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'targetLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      targetLanguageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'targetLanguage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      targetLanguageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetLanguage',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      targetLanguageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'targetLanguage',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      translatedTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'translatedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      translatedTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'translatedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      translatedTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'translatedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      translatedTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'translatedText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      translatedTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'translatedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      translatedTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'translatedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      translatedTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'translatedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      translatedTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'translatedText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      translatedTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'translatedText',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      translatedTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'translatedText',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> typeEqualTo(
    TranslationType value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> typeGreaterThan(
    TranslationType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> typeLessThan(
    TranslationType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> typeBetween(
    TranslationType lower,
    TranslationType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> typeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> typeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> typeIconEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'typeIcon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeIconGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'typeIcon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeIconLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'typeIcon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> typeIconBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'typeIcon',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeIconStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'typeIcon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeIconEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'typeIcon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeIconContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'typeIcon',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition> typeIconMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'typeIcon',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeIconIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'typeIcon',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeIconIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'typeIcon',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeLabelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'typeLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeLabelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'typeLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeLabelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'typeLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeLabelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'typeLabel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeLabelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'typeLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeLabelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'typeLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeLabelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'typeLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeLabelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'typeLabel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeLabelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'typeLabel',
        value: '',
      ));
    });
  }

  QueryBuilder<Translation, Translation, QAfterFilterCondition>
      typeLabelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'typeLabel',
        value: '',
      ));
    });
  }
}

extension TranslationQueryObject
    on QueryBuilder<Translation, Translation, QFilterCondition> {}

extension TranslationQueryLinks
    on QueryBuilder<Translation, Translation, QFilterCondition> {}

extension TranslationQuerySortBy
    on QueryBuilder<Translation, Translation, QSortBy> {
  QueryBuilder<Translation, Translation, QAfterSortBy> sortByAudioDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioDuration', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      sortByAudioDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioDuration', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByAudioUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioUrl', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByAudioUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioUrl', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      sortByHasOffensiveContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasOffensiveContent', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      sortByHasOffensiveContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasOffensiveContent', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByImageLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageLocalPath', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      sortByImageLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageLocalPath', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByLanguagePair() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'languagePair', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      sortByLanguagePairDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'languagePair', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByShortText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shortText', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByShortTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shortText', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortBySourceLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLanguage', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      sortBySourceLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLanguage', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortBySourceText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceText', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortBySourceTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceText', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByTargetLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetLanguage', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      sortByTargetLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetLanguage', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByTranslatedText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatedText', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      sortByTranslatedTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatedText', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByTypeIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeIcon', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByTypeIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeIcon', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByTypeLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeLabel', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> sortByTypeLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeLabel', Sort.desc);
    });
  }
}

extension TranslationQuerySortThenBy
    on QueryBuilder<Translation, Translation, QSortThenBy> {
  QueryBuilder<Translation, Translation, QAfterSortBy> thenByAudioDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioDuration', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      thenByAudioDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioDuration', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByAudioUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioUrl', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByAudioUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioUrl', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      thenByHasOffensiveContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasOffensiveContent', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      thenByHasOffensiveContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasOffensiveContent', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByImageLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageLocalPath', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      thenByImageLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageLocalPath', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByLanguagePair() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'languagePair', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      thenByLanguagePairDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'languagePair', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByShortText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shortText', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByShortTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shortText', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenBySourceLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLanguage', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      thenBySourceLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLanguage', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenBySourceText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceText', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenBySourceTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceText', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByTargetLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetLanguage', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      thenByTargetLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetLanguage', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByTranslatedText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatedText', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy>
      thenByTranslatedTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translatedText', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByTypeIcon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeIcon', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByTypeIconDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeIcon', Sort.desc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByTypeLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeLabel', Sort.asc);
    });
  }

  QueryBuilder<Translation, Translation, QAfterSortBy> thenByTypeLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeLabel', Sort.desc);
    });
  }
}

extension TranslationQueryWhereDistinct
    on QueryBuilder<Translation, Translation, QDistinct> {
  QueryBuilder<Translation, Translation, QDistinct> distinctByAudioDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audioDuration');
    });
  }

  QueryBuilder<Translation, Translation, QDistinct> distinctByAudioUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audioUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Translation, Translation, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Translation, Translation, QDistinct>
      distinctByHasOffensiveContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasOffensiveContent');
    });
  }

  QueryBuilder<Translation, Translation, QDistinct> distinctByImageLocalPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageLocalPath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Translation, Translation, QDistinct> distinctByImageUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Translation, Translation, QDistinct> distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<Translation, Translation, QDistinct> distinctByLanguagePair(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'languagePair', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Translation, Translation, QDistinct> distinctByShortText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shortText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Translation, Translation, QDistinct> distinctBySourceLanguage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceLanguage',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Translation, Translation, QDistinct> distinctBySourceText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Translation, Translation, QDistinct> distinctByTargetLanguage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetLanguage',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Translation, Translation, QDistinct> distinctByTranslatedText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'translatedText',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Translation, Translation, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Translation, Translation, QDistinct> distinctByTypeIcon(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'typeIcon', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Translation, Translation, QDistinct> distinctByTypeLabel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'typeLabel', caseSensitive: caseSensitive);
    });
  }
}

extension TranslationQueryProperty
    on QueryBuilder<Translation, Translation, QQueryProperty> {
  QueryBuilder<Translation, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Translation, double?, QQueryOperations> audioDurationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audioDuration');
    });
  }

  QueryBuilder<Translation, String?, QQueryOperations> audioUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audioUrl');
    });
  }

  QueryBuilder<Translation, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Translation, bool, QQueryOperations>
      hasOffensiveContentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasOffensiveContent');
    });
  }

  QueryBuilder<Translation, String?, QQueryOperations>
      imageLocalPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageLocalPath');
    });
  }

  QueryBuilder<Translation, String?, QQueryOperations> imageUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageUrl');
    });
  }

  QueryBuilder<Translation, bool, QQueryOperations> isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<Translation, String, QQueryOperations> languagePairProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'languagePair');
    });
  }

  QueryBuilder<Translation, String, QQueryOperations> shortTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shortText');
    });
  }

  QueryBuilder<Translation, String, QQueryOperations> sourceLanguageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceLanguage');
    });
  }

  QueryBuilder<Translation, String, QQueryOperations> sourceTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceText');
    });
  }

  QueryBuilder<Translation, String, QQueryOperations> targetLanguageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetLanguage');
    });
  }

  QueryBuilder<Translation, String, QQueryOperations> translatedTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'translatedText');
    });
  }

  QueryBuilder<Translation, TranslationType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<Translation, String, QQueryOperations> typeIconProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'typeIcon');
    });
  }

  QueryBuilder<Translation, String, QQueryOperations> typeLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'typeLabel');
    });
  }
}
