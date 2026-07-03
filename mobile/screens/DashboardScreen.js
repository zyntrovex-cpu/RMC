import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { t } from '../services/i18n';
import api from '../services/api';

const DashboardScreen = ({ navigation, route }) => {
  const { authContext } = route.params;
  const [dashboard, setDashboard] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDashboard = async () => {
      try {
        const response = await api.getDashboard();
        setDashboard(response.data);
      } catch (error) {
        Alert.alert(t('error'), t('connection_error'));
      } finally {
        setLoading(false);
      }
    };

    fetchDashboard();
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
      {/* Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.welcomeText}>{t('dashboard')}</Text>
          {dashboard?.property && (
            <Text style={styles.propertyText}>
              {dashboard.property.plot_no}, {dashboard.property.sector_name}
            </Text>
          )}
        </View>
        <TouchableOpacity onPress={() => authContext.signOut()}>
          <Text style={styles.logoutButton}>{t('logout')}</Text>
        </TouchableOpacity>
      </View>

      {/* Outstanding Dues */}
      {dashboard?.total_outstanding > 0 && (
        <View style={styles.card}>
          <Text style={styles.cardTitle}>{t('dues')}</Text>
          <Text style={styles.amountText}>
            Rs. {dashboard.total_outstanding.toLocaleString()}
          </Text>
        </View>
      )}

      {/* Quick Links */}
      <View style={styles.grid}>
        <TouchableOpacity
          style={styles.gridItem}
          onPress={() => navigation.navigate('Challans')}
        >
          <Text style={styles.gridText}>{t('challans')}</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.gridItem}
          onPress={() => navigation.navigate('VisitorPasses')}
        >
          <Text style={styles.gridText}>{t('visitor_passes')}</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.gridItem}
          onPress={() => navigation.navigate('Noc')}
        >
          <Text style={styles.gridText}>{t('noc')}</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.gridItem}
          onPress={() => navigation.navigate('Complaints')}
        >
          <Text style={styles.gridText}>{t('complaints')}</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.gridItem}
          onPress={() => navigation.navigate('Profile')}
        >
          <Text style={styles.gridText}>{t('profile')}</Text>
        </TouchableOpacity>
      </View>

      {/* Announcements */}
      {dashboard?.announcements && dashboard.announcements.length > 0 && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('announcements')}</Text>
          {dashboard.announcements.map((announcement) => (
            <View key={announcement.id} style={styles.announcementCard}>
              <Text style={styles.announcementTitle}>{announcement.title}</Text>
              <Text style={styles.announcementBody}>{announcement.body}</Text>
            </View>
          ))}
        </View>
      )}
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
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  welcomeText: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
  },
  propertyText: {
    fontSize: 14,
    color: '#ccc',
    marginTop: 4,
  },
  logoutButton: {
    color: '#fff',
    padding: 8,
    borderRadius: 4,
    backgroundColor: 'rgba(255,255,255,0.2)',
  },
  card: {
    backgroundColor: '#fff',
    margin: 16,
    padding: 20,
    borderRadius: 10,
    borderLeftWidth: 4,
    borderLeftColor: '#ff6b6b',
  },
  cardTitle: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
  },
  amountText: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#ff6b6b',
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    padding: 8,
  },
  gridItem: {
    width: '48%',
    backgroundColor: '#fff',
    margin: 8,
    padding: 20,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 100,
  },
  gridText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1A5276',
    textAlign: 'center',
  },
  section: {
    padding: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 12,
  },
  announcementCard: {
    backgroundColor: '#fff',
    padding: 12,
    marginBottom: 8,
    borderRadius: 8,
  },
  announcementTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    marginBottom: 4,
  },
  announcementBody: {
    fontSize: 13,
    color: '#666',
  },
});

export default DashboardScreen;
