import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  Alert,
  TouchableOpacity,
} from 'react-native';
import { t } from '../services/i18n';
import api from '../services/api';

const ChallansScreen = ({ navigation }) => {
  const [challans, setChallans] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchChallans = async () => {
      try {
        const response = await api.getChallans();
        setChallans(response.data || []);
      } catch (error) {
        Alert.alert(t('error'), t('connection_error'));
        navigation.goBack();
      } finally {
        setLoading(false);
      }
    };

    fetchChallans();
  }, []);

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#1A5276" />
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>{t('challans')}</Text>
        <Text style={styles.headerSubtitle}>
          {challans.length} {challans.length === 1 ? 'challan' : 'challans'}
        </Text>
      </View>

      {challans.length === 0 ? (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>{t('no_data')}</Text>
        </View>
      ) : (
        <View style={styles.listContainer}>
          {challans.map((challan) => (
            <View key={challan.id} style={styles.challanCard}>
              <View style={styles.cardHeader}>
                <Text style={styles.challanTitle}>
                  Bill #{challan.bill_no || challan.id}
                </Text>
                <Text
                  style={[
                    styles.statusBadge,
                    challan.status === 'paid'
                      ? styles.statusPaid
                      : styles.statusPending,
                  ]}
                >
                  {challan.status ? challan.status.toUpperCase() : 'PENDING'}
                </Text>
              </View>

              <View style={styles.detailRow}>
                <Text style={styles.label}>{t('amount')}</Text>
                <Text style={styles.amount}>
                  Rs. {challan.amount ? challan.amount.toLocaleString() : '0'}
                </Text>
              </View>

              {challan.due_date && (
                <View style={styles.detailRow}>
                  <Text style={styles.label}>{t('date')}</Text>
                  <Text style={styles.value}>{challan.due_date}</Text>
                </View>
              )}

              {challan.description && (
                <View style={styles.detailRow}>
                  <Text style={styles.label}>{t('description')}</Text>
                  <Text style={styles.description}>{challan.description}</Text>
                </View>
              )}

              {challan.status !== 'paid' && (
                <TouchableOpacity style={styles.payButton}>
                  <Text style={styles.payButtonText}>Pay Now</Text>
                </TouchableOpacity>
              )}
            </View>
          ))}
        </View>
      )}

      <TouchableOpacity
        style={styles.backButton}
        onPress={() => navigation.goBack()}
      >
        <Text style={styles.backButtonText}>{t('back')}</Text>
      </TouchableOpacity>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  header: {
    backgroundColor: '#1A5276',
    color: '#fff',
    padding: 20,
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
  },
  headerSubtitle: {
    fontSize: 14,
    color: '#ccc',
    marginTop: 4,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 40,
  },
  emptyText: {
    fontSize: 16,
    color: '#999',
  },
  listContainer: {
    padding: 16,
  },
  challanCard: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 16,
    marginBottom: 12,
    borderLeftWidth: 4,
    borderLeftColor: '#ff6b6b',
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  challanTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
  },
  statusBadge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 4,
    fontSize: 12,
    fontWeight: '600',
  },
  statusPaid: {
    backgroundColor: '#d4edda',
    color: '#155724',
  },
  statusPending: {
    backgroundColor: '#fff3cd',
    color: '#856404',
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  label: {
    fontSize: 12,
    color: '#999',
    fontWeight: '600',
  },
  value: {
    fontSize: 14,
    color: '#333',
    textAlign: 'right',
    flex: 1,
  },
  amount: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#ff6b6b',
    textAlign: 'right',
  },
  description: {
    fontSize: 12,
    color: '#666',
    textAlign: 'right',
    flex: 1,
  },
  payButton: {
    backgroundColor: '#1A5276',
    borderRadius: 6,
    padding: 10,
    alignItems: 'center',
    marginTop: 12,
  },
  payButtonText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: 'bold',
  },
  backButton: {
    backgroundColor: '#1A5276',
    borderRadius: 8,
    padding: 14,
    alignItems: 'center',
    margin: 16,
    marginTop: 8,
  },
  backButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
});

export default ChallansScreen;
