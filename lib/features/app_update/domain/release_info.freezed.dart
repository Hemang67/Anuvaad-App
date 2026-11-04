// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'release_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReleaseNotes {

 List<String> get whatsNew; List<String> get fixed;
/// Create a copy of ReleaseNotes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReleaseNotesCopyWith<ReleaseNotes> get copyWith => _$ReleaseNotesCopyWithImpl<ReleaseNotes>(this as ReleaseNotes, _$identity);

  /// Serializes this ReleaseNotes to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReleaseNotes;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReleaseNotes&&const DeepCollectionEquality().equals(other.whatsNew, _this.whatsNew)&&const DeepCollectionEquality().equals(other.fixed, _this.fixed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReleaseNotes;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.whatsNew),const DeepCollectionEquality().hash(_this.fixed));
}

@override
String toString() {
  final _this = this as ReleaseNotes;
  return 'ReleaseNotes(whatsNew: ${_this.whatsNew}, fixed: ${_this.fixed})';
}


}

/// @nodoc
abstract mixin class $ReleaseNotesCopyWith<$Res>  {
  factory $ReleaseNotesCopyWith(ReleaseNotes value, $Res Function(ReleaseNotes) _then) = _$ReleaseNotesCopyWithImpl;
@useResult
$Res call({
 List<String> whatsNew, List<String> fixed
});




}
/// @nodoc
class _$ReleaseNotesCopyWithImpl<$Res>
    implements $ReleaseNotesCopyWith<$Res> {
  _$ReleaseNotesCopyWithImpl(this._self, this._then);

  final ReleaseNotes _self;
  final $Res Function(ReleaseNotes) _then;

/// Create a copy of ReleaseNotes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? whatsNew = null,Object? fixed = null,}) {
  return _then(ReleaseNotes(
whatsNew: null == whatsNew ? _self.whatsNew : whatsNew // ignore: cast_nullable_to_non_nullable
as List<String>,fixed: null == fixed ? _self.fixed : fixed // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ReleaseNotes].
extension ReleaseNotesPatterns on ReleaseNotes {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReleaseNotes value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReleaseNotes() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReleaseNotes value)  $default,){
final _that = this;
switch (_that) {
case _ReleaseNotes():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReleaseNotes value)?  $default,){
final _that = this;
switch (_that) {
case _ReleaseNotes() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> whatsNew,  List<String> fixed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReleaseNotes() when $default != null:
return $default(_that.whatsNew,_that.fixed);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> whatsNew,  List<String> fixed)  $default,) {final _that = this;
switch (_that) {
case _ReleaseNotes():
return $default(_that.whatsNew,_that.fixed);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> whatsNew,  List<String> fixed)?  $default,) {final _that = this;
switch (_that) {
case _ReleaseNotes() when $default != null:
return $default(_that.whatsNew,_that.fixed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReleaseNotes implements ReleaseNotes {
  const _ReleaseNotes({required  List<String> whatsNew, required  List<String> fixed}): _whatsNew = whatsNew,_fixed = fixed;
  factory _ReleaseNotes.fromJson(Map<String, dynamic> json) => _$ReleaseNotesFromJson(json);

 final  List<String> _whatsNew;
@override List<String> get whatsNew {
  if (_whatsNew is EqualUnmodifiableListView) return _whatsNew;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_whatsNew);
}

 final  List<String> _fixed;
@override List<String> get fixed {
  if (_fixed is EqualUnmodifiableListView) return _fixed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fixed);
}


/// Create a copy of ReleaseNotes
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReleaseNotesCopyWith<_ReleaseNotes> get copyWith => __$ReleaseNotesCopyWithImpl<_ReleaseNotes>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReleaseNotesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReleaseNotes&&const DeepCollectionEquality().equals(other.whatsNew, _whatsNew)&&const DeepCollectionEquality().equals(other.fixed, _fixed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_whatsNew),const DeepCollectionEquality().hash(_fixed));
}

@override
String toString() {
    return 'ReleaseNotes(whatsNew: $whatsNew, fixed: $fixed)';
}


}

/// @nodoc
abstract mixin class _$ReleaseNotesCopyWith<$Res> implements $ReleaseNotesCopyWith<$Res> {
  factory _$ReleaseNotesCopyWith(_ReleaseNotes value, $Res Function(_ReleaseNotes) _then) = __$ReleaseNotesCopyWithImpl;
@override @useResult
$Res call({
 List<String> whatsNew, List<String> fixed
});




}
/// @nodoc
class __$ReleaseNotesCopyWithImpl<$Res>
    implements _$ReleaseNotesCopyWith<$Res> {
  __$ReleaseNotesCopyWithImpl(this._self, this._then);

  final _ReleaseNotes _self;
  final $Res Function(_ReleaseNotes) _then;

/// Create a copy of ReleaseNotes
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? whatsNew = null,Object? fixed = null,}) {
  return _then(_ReleaseNotes(
whatsNew: null == whatsNew ? _self._whatsNew : whatsNew // ignore: cast_nullable_to_non_nullable
as List<String>,fixed: null == fixed ? _self._fixed : fixed // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ApkAsset {

 String get abi; String get file; Uri get url; int get size; String get sha256;
/// Create a copy of ApkAsset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApkAssetCopyWith<ApkAsset> get copyWith => _$ApkAssetCopyWithImpl<ApkAsset>(this as ApkAsset, _$identity);

  /// Serializes this ApkAsset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ApkAsset;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApkAsset&&(identical(other.abi, _this.abi) || other.abi == _this.abi)&&(identical(other.file, _this.file) || other.file == _this.file)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ApkAsset;
  return Object.hash(runtimeType,_this.abi,_this.file,_this.url,_this.size,_this.sha256);
}

@override
String toString() {
  final _this = this as ApkAsset;
  return 'ApkAsset(abi: ${_this.abi}, file: ${_this.file}, url: ${_this.url}, size: ${_this.size}, sha256: ${_this.sha256})';
}


}

/// @nodoc
abstract mixin class $ApkAssetCopyWith<$Res>  {
  factory $ApkAssetCopyWith(ApkAsset value, $Res Function(ApkAsset) _then) = _$ApkAssetCopyWithImpl;
@useResult
$Res call({
 String abi, String file, Uri url, int size, String sha256
});




}
/// @nodoc
class _$ApkAssetCopyWithImpl<$Res>
    implements $ApkAssetCopyWith<$Res> {
  _$ApkAssetCopyWithImpl(this._self, this._then);

  final ApkAsset _self;
  final $Res Function(ApkAsset) _then;

/// Create a copy of ApkAsset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? abi = null,Object? file = null,Object? url = null,Object? size = null,Object? sha256 = null,}) {
  return _then(ApkAsset(
abi: null == abi ? _self.abi : abi // ignore: cast_nullable_to_non_nullable
as String,file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as Uri,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ApkAsset].
extension ApkAssetPatterns on ApkAsset {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApkAsset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApkAsset() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApkAsset value)  $default,){
final _that = this;
switch (_that) {
case _ApkAsset():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApkAsset value)?  $default,){
final _that = this;
switch (_that) {
case _ApkAsset() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String abi,  String file,  Uri url,  int size,  String sha256)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApkAsset() when $default != null:
return $default(_that.abi,_that.file,_that.url,_that.size,_that.sha256);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String abi,  String file,  Uri url,  int size,  String sha256)  $default,) {final _that = this;
switch (_that) {
case _ApkAsset():
return $default(_that.abi,_that.file,_that.url,_that.size,_that.sha256);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String abi,  String file,  Uri url,  int size,  String sha256)?  $default,) {final _that = this;
switch (_that) {
case _ApkAsset() when $default != null:
return $default(_that.abi,_that.file,_that.url,_that.size,_that.sha256);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApkAsset implements ApkAsset {
  const _ApkAsset({required this.abi, required this.file, required this.url, required this.size, required this.sha256});
  factory _ApkAsset.fromJson(Map<String, dynamic> json) => _$ApkAssetFromJson(json);

@override final  String abi;
@override final  String file;
@override final  Uri url;
@override final  int size;
@override final  String sha256;

/// Create a copy of ApkAsset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApkAssetCopyWith<_ApkAsset> get copyWith => __$ApkAssetCopyWithImpl<_ApkAsset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApkAssetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApkAsset&&(identical(other.abi, abi) || other.abi == abi)&&(identical(other.file, file) || other.file == file)&&(identical(other.url, url) || other.url == url)&&(identical(other.size, size) || other.size == size)&&(identical(other.sha256, sha256) || other.sha256 == sha256));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,abi,file,url,size,sha256);
}

@override
String toString() {
    return 'ApkAsset(abi: $abi, file: $file, url: $url, size: $size, sha256: $sha256)';
}


}

/// @nodoc
abstract mixin class _$ApkAssetCopyWith<$Res> implements $ApkAssetCopyWith<$Res> {
  factory _$ApkAssetCopyWith(_ApkAsset value, $Res Function(_ApkAsset) _then) = __$ApkAssetCopyWithImpl;
@override @useResult
$Res call({
 String abi, String file, Uri url, int size, String sha256
});




}
/// @nodoc
class __$ApkAssetCopyWithImpl<$Res>
    implements _$ApkAssetCopyWith<$Res> {
  __$ApkAssetCopyWithImpl(this._self, this._then);

  final _ApkAsset _self;
  final $Res Function(_ApkAsset) _then;

/// Create a copy of ApkAsset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? abi = null,Object? file = null,Object? url = null,Object? size = null,Object? sha256 = null,}) {
  return _then(_ApkAsset(
abi: null == abi ? _self.abi : abi // ignore: cast_nullable_to_non_nullable
as String,file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as Uri,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ReleaseInfo {

 int get schema; String get version; int get build; DateTime get publishedAt; bool get mandatory; int get minSupportedBuild; ReleaseNotes get notes; List<ApkAsset> get assets; Uri get releaseUrl;
/// Create a copy of ReleaseInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReleaseInfoCopyWith<ReleaseInfo> get copyWith => _$ReleaseInfoCopyWithImpl<ReleaseInfo>(this as ReleaseInfo, _$identity);

  /// Serializes this ReleaseInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReleaseInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReleaseInfo&&(identical(other.schema, _this.schema) || other.schema == _this.schema)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.build, _this.build) || other.build == _this.build)&&(identical(other.publishedAt, _this.publishedAt) || other.publishedAt == _this.publishedAt)&&(identical(other.mandatory, _this.mandatory) || other.mandatory == _this.mandatory)&&(identical(other.minSupportedBuild, _this.minSupportedBuild) || other.minSupportedBuild == _this.minSupportedBuild)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&const DeepCollectionEquality().equals(other.assets, _this.assets)&&(identical(other.releaseUrl, _this.releaseUrl) || other.releaseUrl == _this.releaseUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReleaseInfo;
  return Object.hash(runtimeType,_this.schema,_this.version,_this.build,_this.publishedAt,_this.mandatory,_this.minSupportedBuild,_this.notes,const DeepCollectionEquality().hash(_this.assets),_this.releaseUrl);
}

@override
String toString() {
  final _this = this as ReleaseInfo;
  return 'ReleaseInfo(schema: ${_this.schema}, version: ${_this.version}, build: ${_this.build}, publishedAt: ${_this.publishedAt}, mandatory: ${_this.mandatory}, minSupportedBuild: ${_this.minSupportedBuild}, notes: ${_this.notes}, assets: ${_this.assets}, releaseUrl: ${_this.releaseUrl})';
}


}

/// @nodoc
abstract mixin class $ReleaseInfoCopyWith<$Res>  {
  factory $ReleaseInfoCopyWith(ReleaseInfo value, $Res Function(ReleaseInfo) _then) = _$ReleaseInfoCopyWithImpl;
@useResult
$Res call({
 int schema, String version, int build, DateTime publishedAt, bool mandatory, int minSupportedBuild, ReleaseNotes notes, List<ApkAsset> assets, Uri releaseUrl
});


$ReleaseNotesCopyWith<$Res> get notes;

}
/// @nodoc
class _$ReleaseInfoCopyWithImpl<$Res>
    implements $ReleaseInfoCopyWith<$Res> {
  _$ReleaseInfoCopyWithImpl(this._self, this._then);

  final ReleaseInfo _self;
  final $Res Function(ReleaseInfo) _then;

/// Create a copy of ReleaseInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schema = null,Object? version = null,Object? build = null,Object? publishedAt = null,Object? mandatory = null,Object? minSupportedBuild = null,Object? notes = null,Object? assets = null,Object? releaseUrl = null,}) {
  return _then(ReleaseInfo(
schema: null == schema ? _self.schema : schema // ignore: cast_nullable_to_non_nullable
as int,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,build: null == build ? _self.build : build // ignore: cast_nullable_to_non_nullable
as int,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,mandatory: null == mandatory ? _self.mandatory : mandatory // ignore: cast_nullable_to_non_nullable
as bool,minSupportedBuild: null == minSupportedBuild ? _self.minSupportedBuild : minSupportedBuild // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as ReleaseNotes,assets: null == assets ? _self.assets : assets // ignore: cast_nullable_to_non_nullable
as List<ApkAsset>,releaseUrl: null == releaseUrl ? _self.releaseUrl : releaseUrl // ignore: cast_nullable_to_non_nullable
as Uri,
  ));
}
/// Create a copy of ReleaseInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReleaseNotesCopyWith<$Res> get notes {
  
  return $ReleaseNotesCopyWith<$Res>(_self.notes, (value) {
    return _then(_self.copyWith(notes: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReleaseInfo].
extension ReleaseInfoPatterns on ReleaseInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReleaseInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReleaseInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReleaseInfo value)  $default,){
final _that = this;
switch (_that) {
case _ReleaseInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReleaseInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ReleaseInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schema,  String version,  int build,  DateTime publishedAt,  bool mandatory,  int minSupportedBuild,  ReleaseNotes notes,  List<ApkAsset> assets,  Uri releaseUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReleaseInfo() when $default != null:
return $default(_that.schema,_that.version,_that.build,_that.publishedAt,_that.mandatory,_that.minSupportedBuild,_that.notes,_that.assets,_that.releaseUrl);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schema,  String version,  int build,  DateTime publishedAt,  bool mandatory,  int minSupportedBuild,  ReleaseNotes notes,  List<ApkAsset> assets,  Uri releaseUrl)  $default,) {final _that = this;
switch (_that) {
case _ReleaseInfo():
return $default(_that.schema,_that.version,_that.build,_that.publishedAt,_that.mandatory,_that.minSupportedBuild,_that.notes,_that.assets,_that.releaseUrl);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schema,  String version,  int build,  DateTime publishedAt,  bool mandatory,  int minSupportedBuild,  ReleaseNotes notes,  List<ApkAsset> assets,  Uri releaseUrl)?  $default,) {final _that = this;
switch (_that) {
case _ReleaseInfo() when $default != null:
return $default(_that.schema,_that.version,_that.build,_that.publishedAt,_that.mandatory,_that.minSupportedBuild,_that.notes,_that.assets,_that.releaseUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReleaseInfo implements ReleaseInfo {
  const _ReleaseInfo({required this.schema, required this.version, required this.build, required this.publishedAt, required this.mandatory, required this.minSupportedBuild, required this.notes, required  List<ApkAsset> assets, required this.releaseUrl}): _assets = assets;
  factory _ReleaseInfo.fromJson(Map<String, dynamic> json) => _$ReleaseInfoFromJson(json);

@override final  int schema;
@override final  String version;
@override final  int build;
@override final  DateTime publishedAt;
@override final  bool mandatory;
@override final  int minSupportedBuild;
@override final  ReleaseNotes notes;
 final  List<ApkAsset> _assets;
@override List<ApkAsset> get assets {
  if (_assets is EqualUnmodifiableListView) return _assets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assets);
}

@override final  Uri releaseUrl;

/// Create a copy of ReleaseInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReleaseInfoCopyWith<_ReleaseInfo> get copyWith => __$ReleaseInfoCopyWithImpl<_ReleaseInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReleaseInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReleaseInfo&&(identical(other.schema, schema) || other.schema == schema)&&(identical(other.version, version) || other.version == version)&&(identical(other.build, build) || other.build == build)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.mandatory, mandatory) || other.mandatory == mandatory)&&(identical(other.minSupportedBuild, minSupportedBuild) || other.minSupportedBuild == minSupportedBuild)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.assets, _assets)&&(identical(other.releaseUrl, releaseUrl) || other.releaseUrl == releaseUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,schema,version,build,publishedAt,mandatory,minSupportedBuild,notes,const DeepCollectionEquality().hash(_assets),releaseUrl);
}

@override
String toString() {
    return 'ReleaseInfo(schema: $schema, version: $version, build: $build, publishedAt: $publishedAt, mandatory: $mandatory, minSupportedBuild: $minSupportedBuild, notes: $notes, assets: $assets, releaseUrl: $releaseUrl)';
}


}

/// @nodoc
abstract mixin class _$ReleaseInfoCopyWith<$Res> implements $ReleaseInfoCopyWith<$Res> {
  factory _$ReleaseInfoCopyWith(_ReleaseInfo value, $Res Function(_ReleaseInfo) _then) = __$ReleaseInfoCopyWithImpl;
@override @useResult
$Res call({
 int schema, String version, int build, DateTime publishedAt, bool mandatory, int minSupportedBuild, ReleaseNotes notes, List<ApkAsset> assets, Uri releaseUrl
});


@override $ReleaseNotesCopyWith<$Res> get notes;

}
/// @nodoc
class __$ReleaseInfoCopyWithImpl<$Res>
    implements _$ReleaseInfoCopyWith<$Res> {
  __$ReleaseInfoCopyWithImpl(this._self, this._then);

  final _ReleaseInfo _self;
  final $Res Function(_ReleaseInfo) _then;

/// Create a copy of ReleaseInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schema = null,Object? version = null,Object? build = null,Object? publishedAt = null,Object? mandatory = null,Object? minSupportedBuild = null,Object? notes = null,Object? assets = null,Object? releaseUrl = null,}) {
  return _then(_ReleaseInfo(
schema: null == schema ? _self.schema : schema // ignore: cast_nullable_to_non_nullable
as int,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,build: null == build ? _self.build : build // ignore: cast_nullable_to_non_nullable
as int,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,mandatory: null == mandatory ? _self.mandatory : mandatory // ignore: cast_nullable_to_non_nullable
as bool,minSupportedBuild: null == minSupportedBuild ? _self.minSupportedBuild : minSupportedBuild // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as ReleaseNotes,assets: null == assets ? _self._assets : assets // ignore: cast_nullable_to_non_nullable
as List<ApkAsset>,releaseUrl: null == releaseUrl ? _self.releaseUrl : releaseUrl // ignore: cast_nullable_to_non_nullable
as Uri,
  ));
}

/// Create a copy of ReleaseInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReleaseNotesCopyWith<$Res> get notes {
  
  return $ReleaseNotesCopyWith<$Res>(_self.notes, (value) {
    return _then(_self.copyWith(notes: value));
  });
}
}

// dart format on
