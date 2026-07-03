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

const NocScreen = ({ navigation }) => {
  const [nocs, setNocs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modalVisible, setModalVisible] = useState(false);
  const [purpose, setPurpose] = useState('');
  const [description, setDescription] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    const fetchNocs = async () => {
      try {
        const response = await api.getNocs();
        setNocs(response.data || []);
      } catch (error) {
        Alert.alert(t('error'), t('connection_error'));
        navigation.goBack();
      } finally {
        setLoading(false);
      }
    };

    fetchNocs();
  }, []);

  const handleSubmitNoc = async () => {
    if (!purpose || !description) {
      Alert.alert(t('error'), 'Please fill all fields');
      return;
    }

    setSubmitting(true);
    try {
      await api.createNoc({
        purpose,
        description,
      });
      Alert.alert(t('success'), 'NOC request submitted successfully');
      setPurpose('');
      setDescription('');
      setModalVisible(false);
      const response = await api.getNocs();
      setNocs(response.data || []);
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
        <Text style={styles.headerTitle}>{t('noc')}</Text>
        <Text style={styles.headerSubtitle}>
          {nocs.length} {nocs.length === 1 ? 'request' : 'requests'}
        </Text>
      </View>

      <TouchableOpacity
        style={styles.createButton}
        onPress={() => setModalVisible(true)}
      >
        <Text style={styles.createButtonText}>+ New NOC Request</Text>
      </TouchableOpacity>

      {nocs.length === 0 ? (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>{t('no_data')}</Text>
        </View>
      ) : (
        <View style={styles.listContainer}>
          {nocs.map((noc) => (
            <View key={noc.id} style={styles.nocCard}>
              <View style={styles.cardHeader}>
                <Text style={styles.nocTitle}>{noc.purpose}</Text>
                <Text
                  style={[
                    styles.statusBadge,
                    noc.status === 'approved'
                      ? styles.statusApproved
                      : noc.status === 'rejected'
                      ? styles.statusRejected
                      : styles.statusPending,
                  ]}
                >
                  {noc.status ? noc.status.toUpperCase() : 'PENDING'}
                </Text>
              </View>

              <View style={styles.detailRow}>
                <Text style={styles.label}>{t('description')}</Text>
              </View>
              <Text style={styles.description}>{noc.description}</Text>

              {noc.created_at && (
                <View style={styles.detailRow}>
                  <Text style={styles.label}>{t('date')}</Text>
                  <Text style={styles.value}>{noc.created_at}</Text>
                </View>
              )}

              {noc.reference_no && (
                <View style={styles.detailRow}>
                  <Text style={styles.label}>Reference No</Text>
                  <Text style={styles.value}>{noc.reference_no}</Text>
                </View>
              )}

              {noc.status === 'approved' && noc.document_url && (
                <TouchableOpacity style={styles.downloadButton}>
                  <Text style={styles.downloadButtonText}>Download NOC</Text>
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

      <Modal
        animationType="slide"
        transparent={true}
        visible={modalVisible}
        onRequestClose={() => setModalVisible(false)}
      >
        <View style={styles.centeredView}>
          <View style={styles.modalView}>
            <Text style={styles.modalTitle}>Request NOC</Text>

            <TextInput
              style={styles.input}
              placeholder="Purpose of NOC"
              value={purpose}
              onChangeText={setPurpose}
              editable={!submitting}
            />

            <TextInput
              style={[styles.input, styles.textArea]}
              placeholder="Description (Why do you need this NOC?)"
              value={description}
              onChangeText={setDescription}
              multiline
              numberOfLines={4}
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
                onPress={handleSubmitNoc}
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
    backgroundColor: '#17a2b8',
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
  nocCard: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 16,
    marginBottom: 12,
    borderLeftWidth: 4,
    borderLeftColor: '#17a2b8',
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  nocTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    flex: 1,
  },
  statusBadge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 4,
    fontSize: 11,
    fontWeight: '600',
    marginLeft: 8,
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
  },
  description: {
    fontSize: 14,
    color: '#666',
    lineHeight: 20,
    marginBottom: 12,
  },
  downloadButton: {
    backgroundColor: '#17a2b8',
    borderRadius: 6,
    padding: 10,
    alignItems: 'center',
    marginTop: 12,
  },
  downloadButtonText: {
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
    height: 100,
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

export default NocScreen;
