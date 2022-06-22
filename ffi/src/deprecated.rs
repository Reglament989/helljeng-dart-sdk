// match Function::from(function) {
//     Function::Init => {
//         #[derive(Debug, Deserialize)]
//         struct Args {
//             base_url: String,
//             tokens: (Option<String>, Option<String>),
//             keys: Option<(Vec<u8>, Vec<u8>)>,
//         }
//         let args: Args = serde_json::from_str(args.to_str().unwrap()).unwrap();
//         let mut api = API.write().unwrap();
//         *api = Api::new(args.base_url, args.tokens, args.keys);
//     }
//     Function::Default => {
//         let mut api = API.write().unwrap();
//         *api = Api::default();
//     }
//     Function::Login => {
//         #[derive(Debug, Deserialize)]
//         struct Args {
//             password: String,
//             email: String,
//             username: String,
//             name: Option<String>,
//             device_id: String,
//         }
//         let args: Args = serde_json::from_str(args.to_str().unwrap()).unwrap();
//         let tokens = rt.block_on(async {
//             let mut api = API.write().unwrap();
//             api.user("")
//                 .new(&AccountPayload {
//                     username: args.username,
//                     name: args.name,
//                     email: args.email.clone(),
//                     password: args.password.clone(),
//                     color: None,
//                 })
//                 .await
//                 .unwrap();
//             let sign_public_key = api.encryption.export_sign_public_key().to_vec();
//             let public_key = api.encryption.export_decrypt_public_key().to_vec();
//             api.login(
//                 args.email,
//                 args.password,
//                 args.device_id,
//                 sign_public_key,
//                 public_key,
//             )
//             .await
//             .unwrap();
//             (api.refresh_token.clone(), api.token.clone())
//         });
//         response.message(json!({ "refresh_token": &tokens.0, "token": &tokens.1 }));
//     }
//     Function::NewRoom => {
//         #[derive(Debug, Deserialize)]
//         struct Args {
//             title: String,
//             description: Option<String>,
//         }
//         let args: Args = serde_json::from_str(args.to_str().unwrap()).unwrap();
//         match rt.block_on(async {
//             let mut api = API.write().unwrap();
//             api.room("").new(args.title, args.description).await
//         }) {
//             Ok(_) => {
//                 response.message("OK");
//             }
//             Err(err) => {
//                 response.error(err.to_string());
//             }
//         }
//     }
//     Function::Unknown => todo!(),
// }
