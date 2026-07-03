import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  Alert,
  TouchableOpacity,
  Modal,
  TextInput,
} from 'react-native';
import { t } from '../services/i18n';
import api from '../services/api';

const VisitorPassesScreen = ({ navigation }) => {
  const [passes, setPasses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modalVisible, setModalVisible] = useState(false);
  const [visitorName, setVisitorName] = useState('');
  const [visitorPhone, setVisitorPhone] = useState('');
  const [purpose, setPurpose] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    const fetchPasses = async () => {
      try {
        const response = await api.getVisitorPasses();
        setPasses(response.data || []);
      } catch (error) {
        Alert.alert(t('error'), t('connection_error'));
        navigation.goBack();
      } finally {
        setLoading(false);
      }
    };

    fetchPasses();
  }, []);

  const handleSubmitPass = async () => {
    if (!visitorName || !visitorPhone || !purpose) {
      Alert.alert(t('error'), 'Please fill all fields');
      return;
    }

    setSubmitting(true);
    try {
      await api.createVisitorPass({
        visitor_name: visitorName,
        visitor_phone: visitorPhone,
        purpose,
      });
      Alert.alert(t('success'), 'Visitor pass created successfully');
      setVisitorName('');
      setVisitorPhone('');
      setPurpose('');
      setModalVisible(false);
      const response = await api.getVisitorPasses();
      setPasses(response.data || []);
    } catch (error) {
      Alert.alert(t('error'), error.message || t('connection_error'));
    } finally {
      setSubmitting(false);
    }
  };

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
        <Text style={styles.headerTitle}>{t('visitor_passes')}</Text>
        <Text style={styles.headerSubtitle}>
          {passes.length} {passes.length === 1 ? 'pass' : 'passes'}
        </Text>
      </View>

      <TouchableOpacity
        style={styles.createButton}
        onPress={() => setModalVisible(true)}
      >
        <Text style={styles.createButtonText}>+ New Visitor Pass</Text>
      </TouchableOpacity>

      {passes.length === 0 ? (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>{t('no_data')}</Text>
        </View>
      ) : (
        <View style={styles.listContainer}>
          {passes.map((pass) => (
            <View key={pass.id} style={styles.passCard}>
              <View style={styles.cardHeader}>
                <Text style={styles.passTitle}>{pass.visitor_name}</Text>
                <Text
                  style={[
                    styles.statusBadge,
                    pass.status === 'approved'
                      ? styles.statusApproved
                      : pass.status === 'rejected'
                      ? styles.statusRejected
                      : styles.statusPending,
                  ]}
                >
                  {pass.status ? pass.status.toUpperCase() : 'PENDING'}
                </Text>
              </View>

              <View style={styles.detailRow}>
                <Text style={styles.label}>Phone</Text>
                <Text style={styles.value}>{pass.visitor_phone}</Text>
              </View>

              {pass.purpose && (
                <View style={styles.detailRow}>
                  <Text style={styles.label}>{t('description')}</Text>
                  <Text style={styles.value}>{pass.purpose}</Text>
                </View>
              )}

              {pass.valid_from && (
                <View style={styles.detailRow}>
                  <Text style={styles.label}>Valid From</Text>
                  <Text style={styles.value}>{pass.valid_from}</Text>
                </View>
              )}

              {pass.valid_till && (
                <View style={styles.detailRow}>
                  <Text style={styles.label}>Valid Till</Text>
                  <Text style={styles.value}>{pass.valid_till}</Text>
                </View>
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

      <Modal
        animationType="slide"
        transparent={true}
        visible={modalVisible}
        onRequestClose={() => setModalVisible(false)}
      >
        <View style={styles.centeredView}>
          <View style={styles.modalView}>
            <Text style={styles.modalTitle}>Create Visitor Pass</Text>

            <TextInput
              style={styles.input}
              placeholder="Visitor Name"
              value={visitorName}
              onChangeText={setVisitorName}
              editable={!submitting}
            />

            <TextInput
              style={styles.input}
              placeholder="Visitor Phone"
              value={visitorPhone}
              onChangeText={setVisitorPhone}
              keyboardType="phone-pad"
              editable={!submitting}
            />

            <TextInput
              style={[styles.input, styles.textArea]}
              placeholder="Purpose"
              value={purpose}
              onChangeText={setPurpose}
              multiline
              numberOfLines={3}
              editable={!submitting}
            />

            <View style={styles.modalButtonRow}>
              <TouchableOpacity
                style={[styles.modalButton, styles.cancelButton]}
                onPress={() => setModalVisible(false)}
                disabled={submitting}
              >
                <Text style={styles.cancelButtonText}>{t('cancel')}</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.modalButton, styles.submitButton]}
                onPress={handleSubmitPass}
                disabled={submitting}
              >
                {submitting ? (
                  <ActivityIndicator color="#fff" />
                ) : (
                  <Text style={styles.submitButtonText}>{t('submit')}</Text>
                )}
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
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
  createButton: {
    backgroundColor: '#28a745',
    margin: 16,
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  createButtonText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: 'bold',
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
  passCard: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 16,
    marginBottom: 12,
    borderLeftWidth: 4,
    borderLeftColor: '#1A5276',
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  passTitle: {
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
  statusApproved: {
    backgroundColor: '#d4edda',
    color: '#155724',
  },
  statusPending: {
    backgroundColor: '#fff3cd',
    color: '#856404',
  },
  statusRejected: {
    backgroundColor: '#f8d7da',
    color: '#721c24',
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
  centeredView: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  modalView: {
    backgroundColor: '#fff',
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    padding: 20,
    minHeight: 400,
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 16,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    marginBottom: 12,
    fontSize: 16,
  },
  textArea: {
    height: 80,
    textAlignVertical: 'top',
  },
  modalButtonRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
    marginTop: 16,
  },
  modalButton: {
    flex: 1,
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  cancelButton: {
    backgroundColor: '#ddd',
  },
  cancelButtonText: {
    color: '#333',
    fontSize: 16,
    fontWeight: 'bold',
  },
  submitButton: {
    backgroundColor: '#1A5276',
  },
  submitButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
});

export default VisitorPassesScreen;
