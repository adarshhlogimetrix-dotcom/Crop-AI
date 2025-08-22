// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:cropai/APIClient.dart';
// import 'package:shared_preferences/shared_preferences.dart';


// class Logincontroller {
//   final APIClient apiClient;


// Logincontroller({required this.apiClient});


// Future<Map<String,dynamic>> login(String email,String password) async{

// var connectivityResult = await Connectivity().checkConnectivity();

// if(connectivityResult==ConnectivityResult.none){
 
//  throw Exception('NO internet connection');

// }
// // call api

// final response = await apiClient.loginUser(email,password);

// if(response.containsKey('token')){
//   // save token and user ID

//   final Prefs = await SharedPreferences.getInstance();
//   await Prefs.setString('auth_token',response['token']);
//  if(response.containsKey('user')&& response ['user']['id']!=null){
//   await Prefs.setInt('user_id',response['user']['id']);
//  }

//  return{
//   'success':'true',
//   'message': response['message']??'login successful',
//  };
// }else if(response.containsKey('error')){
//   return {
//     'success':false,
//      'message':response['error'],
//   };
// }else{
//   throw Exception('Unexpected response fromat');
// }
// }
// }