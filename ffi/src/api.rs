use std::{
    ffi::{CStr, CString},
    os::raw::c_char,
    sync::RwLock,
};

use derive_builder::Builder;
use hj_sdk::encryption::Encryption;
use lazy_static::lazy_static;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

lazy_static! {
    static ref API: RwLock<Encryption> = RwLock::new(Encryption::default());
}

#[derive(Debug, Deserialize, Clone)]
enum Function {
    Init,
    Default,
    Login,
    NewRoom,
    EncryptAndSign,
    DecryptAndVerify,
    ExchangeKey,
    Unknown,
}

impl From<&str> for Function {
    fn from(source: &str) -> Self {
        match source {
            "init" | "Init" => Function::Init,
            "default" | "Default" => Function::Default,
            "login" | "Login" => Function::Login,
            "EncryptAndSign" => Function::EncryptAndSign,
            "DecryptAndVerify" => Function::DecryptAndVerify,
            "ExchangeKey" => Function::ExchangeKey,
            "newRoom" | "NewRoom" | "new_room" => Function::NewRoom,
            _ => Function::Unknown,
        }
    }
}

impl Default for Function {
    fn default() -> Self {
        Function::Unknown
    }
}

#[derive(Default, Builder, Debug, Serialize)]
struct FFIResponse {
    #[builder(setter(into, strip_option), default)]
    error: Option<String>,
    #[builder(setter(into, strip_option), default)]
    message: Value,
}

impl FFIResponse {
    fn to_ptr(&self) -> *mut c_char {
        let response = serde_json::to_string(self).unwrap();
        let c_str_response = CString::new(response).unwrap();
        c_str_response.into_raw()
    }
}

#[no_mangle]
pub extern "C" fn invoke(function: *const c_char, args: *const c_char) -> *mut c_char {
    let c_str = unsafe { CStr::from_ptr(function) };
    let args = unsafe { CStr::from_ptr(args) };
    let mut response = FFIResponseBuilder::default();
    match c_str.to_str() {
        Ok(function) => match Function::from(function) {
            Function::Init => {
                #[derive(Debug, Deserialize)]
                struct Args {
                    x25519: [u8; 32],
                    ed25519: [u8; 32],
                }
                let args: Args = serde_json::from_str(args.to_str().unwrap()).unwrap();
                let mut api = API.write().unwrap();
                *api = Encryption::new(args.x25519, args.ed25519);
                response.message(json!({"x25519_public": api.export_exchange_public_key(), "ed25519_public": api.export_sign_public_key()}));
            }
            Function::EncryptAndSign => {
                #[derive(Debug, Deserialize)]
                struct Args {
                    body: Vec<u8>,
                    key: [u8; 32],
                }
                let args: Args = serde_json::from_str(args.to_str().unwrap()).unwrap();
                let api = API.read().unwrap();
                let (encrypted, nonce) = api.encrypt(&args.body, &args.key);
                let signature = api.sign(&encrypted);
                response.message(
                        json!({"encrypted": encrypted, "nonce": nonce, "signature": signature.to_vec()}),
                    );
            }
            Function::DecryptAndVerify => {
                #[derive(Debug, Deserialize)]
                struct Args {
                    encrypted: Vec<u8>,
                    nonce: [u8; 12],
                    signature: Vec<u8>,
                    public_key: [u8; 32],
                    key: [u8; 32],
                }
                let args: Args = serde_json::from_str(args.to_str().unwrap()).unwrap();
                let api = API.read().unwrap();
                if api.verify(&args.encrypted, &args.signature, &args.public_key) {
                    let body = api.decrypt(&args.encrypted, &args.nonce, &args.key);
                    response.message(json!(body));
                } else {
                    response.error("ERROR, signature invalid");
                }
            }
            Function::ExchangeKey => {
                #[derive(Debug, Deserialize)]
                struct Args {
                    key: [u8; 32],
                }
                let args: Args = serde_json::from_str(args.to_str().unwrap()).unwrap();
                let api = API.read().unwrap();
                let exchanged = api.exchange_key(args.key);
                response.message(json!(exchanged));
            }
            Function::Default => todo!(),
            Function::Login => todo!(),
            Function::NewRoom => todo!(),
            Function::Unknown => todo!(),
        },
        Err(_) => {
            response.error("Not valid pointer for json input");
        }
    };
    response.build().unwrap().to_ptr()
}

#[no_mangle]
pub extern "C" fn free(s: *mut c_char) {
    if s.is_null() {
        return;
    }
    unsafe { CString::from_raw(s) };
}

#[no_mangle]
pub extern "C" fn rust_release_mode() -> bool {
    cfg!(not(debug_assertions))
}
