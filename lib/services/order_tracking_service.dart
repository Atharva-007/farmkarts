import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order_model.dart';

class OrderTrackingService {
  static final OrderTrackingService _instance =
      OrderTrackingService._internal();
  factory OrderTrackingService() => _instance;
  OrderTrackingService._internal();

  static const String baseUrl = 'http://localhost:3000/api';

  // Get all orders for a user
  Future<List<OrderModel>> getOrders({
    String? buyerId,
    String? sellerId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        if (buyerId != null) 'buyerId': buyerId,
        if (sellerId != null) 'sellerId': sellerId,
        if (status != null) 'status': status,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri =
          Uri.parse('$baseUrl/orders').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final ordersData = List<Map<String, dynamic>>.from(data['data']);
          return ordersData
              .map((orderData) =>
                  OrderModel.fromMap(orderData['id'] ?? '', orderData))
              .toList();
        }
      }
      return [];
    } catch (e) {
      // print('Error fetching orders: $e');
      return [];
    }
  }

  // Get single order with full details
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return OrderModel.fromMap(data['data']['id'] ?? '', data['data']);
        }
      }
      return null;
    } catch (e) {
      // print('Error fetching order: $e');
      return null;
    }
  }

  // Track order by tracking ID
  Future<OrderTrackingDetails?> trackOrder(String trackingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/track/$trackingId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return OrderTrackingDetails.fromMap(data['data']);
        }
      }
      return null;
    } catch (e) {
      // print('Error tracking order: $e');
      return null;
    }
  }

  // Update order status (for sellers)
  Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
    required String updatedBy,
    String? message,
    String? trackingNumber,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          'message': message,
          'trackingNumber': trackingNumber,
          'updatedBy': updatedBy,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      // print('Error updating order status: $e');
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder({
    required String orderId,
    required String userId,
    required String reason,
  }) async {
    try {
      return await updateOrderStatus(
        orderId: orderId,
        status: 'cancelled',
        updatedBy: userId,
        message: 'Order cancelled: $reason',
      );
    } catch (e) {
      // print('Error cancelling order: $e');
      return false;
    }
  }

  // Confirm order (for sellers)
  Future<bool> confirmOrder({
    required String orderId,
    required String sellerId,
    String? estimatedDeliveryDate,
  }) async {
    try {
      return await updateOrderStatus(
        orderId: orderId,
        status: 'confirmed',
        updatedBy: sellerId,
        message: estimatedDeliveryDate != null
            ? 'Order confirmed. Estimated delivery: $estimatedDeliveryDate'
            : 'Order confirmed and will be processed soon',
      );
    } catch (e) {
      // print('Error confirming order: $e');
      return false;
    }
  }

  // Mark order as shipped
  Future<bool> shipOrder({
    required String orderId,
    required String sellerId,
    required String trackingNumber,
    String? courierName,
  }) async {
    try {
      return await updateOrderStatus(
        orderId: orderId,
        status: 'shipped',
        updatedBy: sellerId,
        message: courierName != null
            ? 'Order shipped via $courierName'
            : 'Order has been shipped',
        trackingNumber: trackingNumber,
      );
    } catch (e) {
      // print('Error shipping order: $e');
      return false;
    }
  }

  // Mark order as delivered
  Future<bool> deliverOrder({
    required String orderId,
    required String updatedBy,
    String? deliveryNotes,
  }) async {
    try {
      return await updateOrderStatus(
        orderId: orderId,
        status: 'delivered',
        updatedBy: updatedBy,
        message: deliveryNotes ?? 'Order has been delivered successfully',
      );
    } catch (e) {
      // print('Error marking order as delivered: $e');
      return false;
    }
  }

  // Get order analytics
  Future<OrderAnalytics?> getOrderAnalytics(String userId,
      {required bool isSeller}) async {
    try {
      final queryParams = {
        'type': isSeller ? 'seller' : 'buyer',
      };

      final uri = Uri.parse('$baseUrl/users/$userId/stats')
          .replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return OrderAnalytics.fromMap(data['data']);
        }
      }
      return null;
    } catch (e) {
      // print('Error fetching order analytics: $e');
      return null;
    }
  }

  // Get recent order activities
  Future<List<OrderActivity>> getRecentActivities(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/activities'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final activitiesData = List<Map<String, dynamic>>.from(data['data']);
          return activitiesData
              .map((activity) => OrderActivity.fromMap(activity))
              .toList();
        }
      }
      return [];
    } catch (e) {
      // print('Error fetching recent activities: $e');
      return [];
    }
  }

  // Search orders
  Future<List<OrderModel>> searchOrders({
    required String userId,
    required bool isSeller,
    String? query,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        if (isSeller) 'sellerId': userId else 'buyerId': userId,
        if (status != null) 'status': status,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final uri =
          Uri.parse('$baseUrl/orders').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final ordersData = List<Map<String, dynamic>>.from(data['data']);
          List<OrderModel> orders = ordersData
              .map((orderData) =>
                  OrderModel.fromMap(orderData['id'] ?? '', orderData))
              .toList();

          // Apply client-side search filter if query provided
          if (query != null && query.isNotEmpty) {
            final queryLower = query.toLowerCase();
            orders = orders
                .where((order) =>
                    order.productName.toLowerCase().contains(queryLower) ||
                    (order.trackingId ?? '')
                        .toLowerCase()
                        .contains(queryLower) ||
                    order.buyerName.toLowerCase().contains(queryLower) ||
                    order.sellerName.toLowerCase().contains(queryLower))
                .toList();
          }

          return orders;
        }
      }
      return [];
    } catch (e) {
      // print('Error searching orders: $e');
      return [];
    }
  }

  // Generate order report
  Future<OrderReport?> generateOrderReport({
    required String userId,
    required bool isSeller,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final orders = await searchOrders(
        userId: userId,
        isSeller: isSeller,
        startDate: startDate,
        endDate: endDate,
      );

      if (orders.isEmpty) {
        return null;
      }

      double totalRevenue = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;
      int pendingOrders = 0;

      for (final order in orders) {
        switch (order.status) {
          case 'delivered':
            completedOrders++;
            totalRevenue += order.totalAmount;
            break;
          case 'cancelled':
            cancelledOrders++;
            break;
          default:
            pendingOrders++;
            break;
        }
      }

      return OrderReport(
        totalOrders: orders.length,
        completedOrders: completedOrders,
        cancelledOrders: cancelledOrders,
        pendingOrders: pendingOrders,
        totalRevenue: totalRevenue,
        averageOrderValue:
            completedOrders > 0 ? totalRevenue / completedOrders : 0,
        startDate: startDate,
        endDate: endDate,
        orders: orders,
      );
    } catch (e) {
      // print('Error generating order report: $e');
      return null;
    }
  }
}

// Supporting Models
class OrderTrackingDetails {
  final OrderModel order;
  final List<TrackingTimeline> trackingTimeline;
  final DateTime? estimatedDelivery;
  final String currentStatus;

  OrderTrackingDetails({
    required this.order,
    required this.trackingTimeline,
    this.estimatedDelivery,
    required this.currentStatus,
  });

  factory OrderTrackingDetails.fromMap(Map<String, dynamic> map) {
    return OrderTrackingDetails(
      order: OrderModel.fromMap(map['order']['id'] ?? '', map['order']),
      trackingTimeline: (map['trackingTimeline'] as List<dynamic>?)
              ?.map((timeline) => TrackingTimeline.fromMap(timeline))
              .toList() ??
          [],
      estimatedDelivery: map['estimatedDelivery'] != null
          ? DateTime.parse(map['estimatedDelivery'])
          : null,
      currentStatus: map['status'] ?? 'pending',
    );
  }
}

class TrackingTimeline {
  final String status;
  final DateTime? timestamp;
  final String message;
  final String updatedBy;
  final bool completed;

  TrackingTimeline({
    required this.status,
    this.timestamp,
    required this.message,
    required this.updatedBy,
    this.completed = false,
  });

  factory TrackingTimeline.fromMap(Map<String, dynamic> map) {
    return TrackingTimeline(
      status: map['status'] ?? '',
      timestamp:
          map['timestamp'] != null ? DateTime.parse(map['timestamp']) : null,
      message: map['message'] ?? '',
      updatedBy: map['updatedBy'] ?? '',
      completed: map['completed'] ?? false,
    );
  }
}

class OrderAnalytics {
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final double pendingRevenue;
  final double avgOrderValue;
  final double completionRate;

  OrderAnalytics({
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    required this.pendingRevenue,
    required this.avgOrderValue,
    required this.completionRate,
  });

  factory OrderAnalytics.fromMap(Map<String, dynamic> map) {
    return OrderAnalytics(
      totalOrders: map['totalOrders'] ?? 0,
      completedOrders: map['completedOrders'] ?? 0,
      pendingOrders: map['pendingOrders'] ?? 0,
      cancelledOrders: map['cancelledOrders'] ?? 0,
      totalRevenue: (map['totalRevenue'] ?? 0).toDouble(),
      pendingRevenue: (map['pendingRevenue'] ?? 0).toDouble(),
      avgOrderValue: (map['avgOrderValue'] ?? 0).toDouble(),
      completionRate: (map['completionRate'] ?? 0).toDouble(),
    );
  }
}

class OrderActivity {
  final String id;
  final String action;
  final String description;
  final DateTime timestamp;
  final String? orderId;

  OrderActivity({
    required this.id,
    required this.action,
    required this.description,
    required this.timestamp,
    this.orderId,
  });

  factory OrderActivity.fromMap(Map<String, dynamic> map) {
    return OrderActivity(
      id: map['id'] ?? '',
      action: map['action'] ?? '',
      description: map['description'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      orderId: map['orderId'],
    );
  }
}

class OrderReport {
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int pendingOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final DateTime startDate;
  final DateTime endDate;
  final List<OrderModel> orders;

  OrderReport({
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.pendingOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.startDate,
    required this.endDate,
    required this.orders,
  });
}
