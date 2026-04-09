use axum::{
    Json,
    response::IntoResponse,
    http::StatusCode,
    Router,
    routing::get,
    extract::State,
};
use serde::{Serialize, Deserialize};
use std::net::{IpAddr, Ipv4Addr};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

#[derive(Clone)]
struct AppState {
    healthy: Arc<AtomicBool>,
}

#[derive(Serialize, Deserialize)]
struct InfoResponse {
    ip: String,
    hostname: String,
    local_ip: String,
}

#[derive(Serialize, Deserialize)]
struct HealthResponse {
    status: String,
    message: String,
}

async fn get_info() -> impl InfoResponse {}