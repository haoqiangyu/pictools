// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_codec.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ImageFormat {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() png,
    required TResult Function(int quality) jpg,
    required TResult Function(int quality, bool lossless) webP,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? png,
    TResult? Function(int quality)? jpg,
    TResult? Function(int quality, bool lossless)? webP,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? png,
    TResult Function(int quality)? jpg,
    TResult Function(int quality, bool lossless)? webP,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ImageFormat_Png value) png,
    required TResult Function(ImageFormat_Jpg value) jpg,
    required TResult Function(ImageFormat_WebP value) webP,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ImageFormat_Png value)? png,
    TResult? Function(ImageFormat_Jpg value)? jpg,
    TResult? Function(ImageFormat_WebP value)? webP,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ImageFormat_Png value)? png,
    TResult Function(ImageFormat_Jpg value)? jpg,
    TResult Function(ImageFormat_WebP value)? webP,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImageFormatCopyWith<$Res> {
  factory $ImageFormatCopyWith(
    ImageFormat value,
    $Res Function(ImageFormat) then,
  ) = _$ImageFormatCopyWithImpl<$Res, ImageFormat>;
}

/// @nodoc
class _$ImageFormatCopyWithImpl<$Res, $Val extends ImageFormat>
    implements $ImageFormatCopyWith<$Res> {
  _$ImageFormatCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImageFormat
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$ImageFormat_PngImplCopyWith<$Res> {
  factory _$$ImageFormat_PngImplCopyWith(
    _$ImageFormat_PngImpl value,
    $Res Function(_$ImageFormat_PngImpl) then,
  ) = __$$ImageFormat_PngImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ImageFormat_PngImplCopyWithImpl<$Res>
    extends _$ImageFormatCopyWithImpl<$Res, _$ImageFormat_PngImpl>
    implements _$$ImageFormat_PngImplCopyWith<$Res> {
  __$$ImageFormat_PngImplCopyWithImpl(
    _$ImageFormat_PngImpl _value,
    $Res Function(_$ImageFormat_PngImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ImageFormat
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ImageFormat_PngImpl extends ImageFormat_Png {
  const _$ImageFormat_PngImpl() : super._();

  @override
  String toString() {
    return 'ImageFormat.png()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ImageFormat_PngImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() png,
    required TResult Function(int quality) jpg,
    required TResult Function(int quality, bool lossless) webP,
  }) {
    return png();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? png,
    TResult? Function(int quality)? jpg,
    TResult? Function(int quality, bool lossless)? webP,
  }) {
    return png?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? png,
    TResult Function(int quality)? jpg,
    TResult Function(int quality, bool lossless)? webP,
    required TResult orElse(),
  }) {
    if (png != null) {
      return png();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ImageFormat_Png value) png,
    required TResult Function(ImageFormat_Jpg value) jpg,
    required TResult Function(ImageFormat_WebP value) webP,
  }) {
    return png(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ImageFormat_Png value)? png,
    TResult? Function(ImageFormat_Jpg value)? jpg,
    TResult? Function(ImageFormat_WebP value)? webP,
  }) {
    return png?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ImageFormat_Png value)? png,
    TResult Function(ImageFormat_Jpg value)? jpg,
    TResult Function(ImageFormat_WebP value)? webP,
    required TResult orElse(),
  }) {
    if (png != null) {
      return png(this);
    }
    return orElse();
  }
}

abstract class ImageFormat_Png extends ImageFormat {
  const factory ImageFormat_Png() = _$ImageFormat_PngImpl;
  const ImageFormat_Png._() : super._();
}

/// @nodoc
abstract class _$$ImageFormat_JpgImplCopyWith<$Res> {
  factory _$$ImageFormat_JpgImplCopyWith(
    _$ImageFormat_JpgImpl value,
    $Res Function(_$ImageFormat_JpgImpl) then,
  ) = __$$ImageFormat_JpgImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int quality});
}

/// @nodoc
class __$$ImageFormat_JpgImplCopyWithImpl<$Res>
    extends _$ImageFormatCopyWithImpl<$Res, _$ImageFormat_JpgImpl>
    implements _$$ImageFormat_JpgImplCopyWith<$Res> {
  __$$ImageFormat_JpgImplCopyWithImpl(
    _$ImageFormat_JpgImpl _value,
    $Res Function(_$ImageFormat_JpgImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ImageFormat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? quality = null}) {
    return _then(
      _$ImageFormat_JpgImpl(
        quality: null == quality
            ? _value.quality
            : quality // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$ImageFormat_JpgImpl extends ImageFormat_Jpg {
  const _$ImageFormat_JpgImpl({required this.quality}) : super._();

  @override
  final int quality;

  @override
  String toString() {
    return 'ImageFormat.jpg(quality: $quality)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImageFormat_JpgImpl &&
            (identical(other.quality, quality) || other.quality == quality));
  }

  @override
  int get hashCode => Object.hash(runtimeType, quality);

  /// Create a copy of ImageFormat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImageFormat_JpgImplCopyWith<_$ImageFormat_JpgImpl> get copyWith =>
      __$$ImageFormat_JpgImplCopyWithImpl<_$ImageFormat_JpgImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() png,
    required TResult Function(int quality) jpg,
    required TResult Function(int quality, bool lossless) webP,
  }) {
    return jpg(quality);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? png,
    TResult? Function(int quality)? jpg,
    TResult? Function(int quality, bool lossless)? webP,
  }) {
    return jpg?.call(quality);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? png,
    TResult Function(int quality)? jpg,
    TResult Function(int quality, bool lossless)? webP,
    required TResult orElse(),
  }) {
    if (jpg != null) {
      return jpg(quality);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ImageFormat_Png value) png,
    required TResult Function(ImageFormat_Jpg value) jpg,
    required TResult Function(ImageFormat_WebP value) webP,
  }) {
    return jpg(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ImageFormat_Png value)? png,
    TResult? Function(ImageFormat_Jpg value)? jpg,
    TResult? Function(ImageFormat_WebP value)? webP,
  }) {
    return jpg?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ImageFormat_Png value)? png,
    TResult Function(ImageFormat_Jpg value)? jpg,
    TResult Function(ImageFormat_WebP value)? webP,
    required TResult orElse(),
  }) {
    if (jpg != null) {
      return jpg(this);
    }
    return orElse();
  }
}

abstract class ImageFormat_Jpg extends ImageFormat {
  const factory ImageFormat_Jpg({required final int quality}) =
      _$ImageFormat_JpgImpl;
  const ImageFormat_Jpg._() : super._();

  int get quality;

  /// Create a copy of ImageFormat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImageFormat_JpgImplCopyWith<_$ImageFormat_JpgImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ImageFormat_WebPImplCopyWith<$Res> {
  factory _$$ImageFormat_WebPImplCopyWith(
    _$ImageFormat_WebPImpl value,
    $Res Function(_$ImageFormat_WebPImpl) then,
  ) = __$$ImageFormat_WebPImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int quality, bool lossless});
}

/// @nodoc
class __$$ImageFormat_WebPImplCopyWithImpl<$Res>
    extends _$ImageFormatCopyWithImpl<$Res, _$ImageFormat_WebPImpl>
    implements _$$ImageFormat_WebPImplCopyWith<$Res> {
  __$$ImageFormat_WebPImplCopyWithImpl(
    _$ImageFormat_WebPImpl _value,
    $Res Function(_$ImageFormat_WebPImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ImageFormat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? quality = null, Object? lossless = null}) {
    return _then(
      _$ImageFormat_WebPImpl(
        quality: null == quality
            ? _value.quality
            : quality // ignore: cast_nullable_to_non_nullable
                  as int,
        lossless: null == lossless
            ? _value.lossless
            : lossless // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$ImageFormat_WebPImpl extends ImageFormat_WebP {
  const _$ImageFormat_WebPImpl({required this.quality, required this.lossless})
    : super._();

  @override
  final int quality;
  @override
  final bool lossless;

  @override
  String toString() {
    return 'ImageFormat.webP(quality: $quality, lossless: $lossless)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImageFormat_WebPImpl &&
            (identical(other.quality, quality) || other.quality == quality) &&
            (identical(other.lossless, lossless) ||
                other.lossless == lossless));
  }

  @override
  int get hashCode => Object.hash(runtimeType, quality, lossless);

  /// Create a copy of ImageFormat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImageFormat_WebPImplCopyWith<_$ImageFormat_WebPImpl> get copyWith =>
      __$$ImageFormat_WebPImplCopyWithImpl<_$ImageFormat_WebPImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() png,
    required TResult Function(int quality) jpg,
    required TResult Function(int quality, bool lossless) webP,
  }) {
    return webP(quality, lossless);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? png,
    TResult? Function(int quality)? jpg,
    TResult? Function(int quality, bool lossless)? webP,
  }) {
    return webP?.call(quality, lossless);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? png,
    TResult Function(int quality)? jpg,
    TResult Function(int quality, bool lossless)? webP,
    required TResult orElse(),
  }) {
    if (webP != null) {
      return webP(quality, lossless);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ImageFormat_Png value) png,
    required TResult Function(ImageFormat_Jpg value) jpg,
    required TResult Function(ImageFormat_WebP value) webP,
  }) {
    return webP(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ImageFormat_Png value)? png,
    TResult? Function(ImageFormat_Jpg value)? jpg,
    TResult? Function(ImageFormat_WebP value)? webP,
  }) {
    return webP?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ImageFormat_Png value)? png,
    TResult Function(ImageFormat_Jpg value)? jpg,
    TResult Function(ImageFormat_WebP value)? webP,
    required TResult orElse(),
  }) {
    if (webP != null) {
      return webP(this);
    }
    return orElse();
  }
}

abstract class ImageFormat_WebP extends ImageFormat {
  const factory ImageFormat_WebP({
    required final int quality,
    required final bool lossless,
  }) = _$ImageFormat_WebPImpl;
  const ImageFormat_WebP._() : super._();

  int get quality;
  bool get lossless;

  /// Create a copy of ImageFormat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImageFormat_WebPImplCopyWith<_$ImageFormat_WebPImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
