part of 'structs.dart';

class WeatherLocation {
  final double latitude;
  final double longitude;
  final double generationtime_ms;
  final int utc_offset_seconds;
  final String timezone;
  final String timezone_abbreviation;
  final double elevation;
  final WeatherUnits current_weather_units;
  final CurrentWeather current_weather;

  WeatherLocation({
    required this.latitude,
    required this.longitude,
    required this.generationtime_ms,
    required this.utc_offset_seconds,
    required this.timezone,
    required this.timezone_abbreviation,
    required this.elevation,
    required this.current_weather_units,
    required this.current_weather,
  });

  factory WeatherLocation.fromJson(Map<String, dynamic> json) {
    return WeatherLocation(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      generationtime_ms: json['generationtime_ms']?.toDouble() ?? 0.0,
      utc_offset_seconds: json['utc_offset_seconds'] ?? 0,
      timezone: json['timezone'] ?? '',
      timezone_abbreviation: json['timezone_abbreviation'] ?? '',
      elevation: json['elevation']?.toDouble() ?? 0.0,
      current_weather_units: WeatherUnits.fromJson(json['current_weather_units'] ?? {}),
      current_weather: CurrentWeather.fromJson(json['current_weather'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'generationtime_ms': generationtime_ms,
      'utc_offset_seconds': utc_offset_seconds,
      'timezone': timezone,
      'timezone_abbreviation': timezone_abbreviation,
      'elevation': elevation,
      'current_weather_units': current_weather_units.toJson(),
      'current_weather': current_weather.toJson(),
    };
  }
}

class WeatherUnits {
  final String time;
  final String interval;
  final String temperature;
  final String windspeed;
  final String winddirection;
  final String is_day;
  final String weathercode;

  WeatherUnits({
    required this.time,
    required this.interval,
    required this.temperature,
    required this.windspeed,
    required this.winddirection,
    required this.is_day,
    required this.weathercode,
  });

  factory WeatherUnits.fromJson(Map<String, dynamic> json) {
    return WeatherUnits(
      time: json['time'] ?? '',
      interval: json['interval'] ?? '',
      temperature: json['temperature'] ?? '',
      windspeed: json['windspeed'] ?? '',
      winddirection: json['winddirection'] ?? '',
      is_day: json['is_day'] ?? '',
      weathercode: json['weathercode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'interval': interval,
      'temperature': temperature,
      'windspeed': windspeed,
      'winddirection': winddirection,
      'is_day': is_day,
      'weathercode': weathercode,
    };
  }
}

class CurrentWeather {
  final String time;
  final int interval;
  final double temperature;
  final double windspeed;
  final int winddirection;
  final int is_day;
  final int weathercode;

  CurrentWeather({
    required this.time,
    required this.interval,
    required this.temperature,
    required this.windspeed,
    required this.winddirection,
    required this.is_day,
    required this.weathercode,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      time: json['time'] ?? '',
      interval: json['interval'] ?? 0,
      temperature: json['temperature']?.toDouble() ?? 0.0,
      windspeed: json['windspeed']?.toDouble() ?? 0.0,
      winddirection: json['winddirection'] ?? 0,
      is_day: json['is_day'] ?? 0,
      weathercode: json['weathercode'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'interval': interval,
      'temperature': temperature,
      'windspeed': windspeed,
      'winddirection': winddirection,
      'is_day': is_day,
      'weathercode': weathercode,
    };
  }
}