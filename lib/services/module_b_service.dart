import 'package:latlong2/latlong.dart';
import '../models/boundary_alert.dart';
import '../core/constants/village_constants.dart';

/// Module B Service Interface — Digital Fencing
///
/// [INTEGRATION-READY] This abstract interface defines the contract for
/// Module B's satellite-based boundary monitoring. The default implementation
/// returns seed data (approximate CFR polygon + no active alerts).
/// When the GEE + Sentinel-2 pipeline is ready, create a new implementation
/// that calls the FastAPI geospatial service endpoint.
///
/// Integration points:
///   - CFR boundary polygon → PostGIS query via FastAPI
///   - NDVI change detection → GEE + Siamese CNN pipeline
///   - Alert dispatch → SMS gateway + in-app notification
abstract class ModuleBService {
  /// Get CFR boundary polygon for a village
  ///
  /// Default: Approximate polygon from Jawhar taluka geography
  /// Future: PostGIS query for exact surveyed boundary
  Future<List<LatLng>> getCFRBoundary(String villageId);

  /// Get active boundary alerts for a village
  ///
  /// Default: Empty list (no satellite pipeline connected)
  /// Future: Alerts from scheduled GEE + NDVI change-detection jobs
  Future<List<BoundaryAlert>> getAlerts(String villageId);

  /// Report an alert to authorities
  ///
  /// Default: Marks as reported locally
  /// Future: Triggers SMS + notification dispatch via FastAPI
  Future<void> reportAlert(String alertId, String reportType);
}

/// Default implementation — uses seed data, works offline
class DefaultModuleBService implements ModuleBService {
  @override
  Future<List<LatLng>> getCFRBoundary(String villageId) async {
    // Return approximate CFR boundary for Ozhar from village constants
    return VillageConstants.cfrBoundaryPolygon;
  }

  @override
  Future<List<BoundaryAlert>> getAlerts(String villageId) async {
    // No active alerts — satellite pipeline not yet connected
    // Return empty list; when GEE pipeline is live, this will return real alerts
    return [];
  }

  @override
  Future<void> reportAlert(String alertId, String reportType) async {
    // Locally mark as reported
    // Future: dispatch via FastAPI → SMS gateway + notification
  }
}
