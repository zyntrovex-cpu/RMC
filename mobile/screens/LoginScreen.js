import React, { useState } from 'react';
import {
  View,
  TextInput,
  TouchableOpacity,
  Text,
  StyleSheet,
  ActivityIndicator,
  Alert,
  ScrollView,
} from 'react-native';
import { t } from '../services/i18n';
import api from '../services/api';

const LoginScreen = ({ route }) => {
  const { authContext } = route.params;
  const [mobile, setMobile] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [language, setLanguage] = useState('en');

  const handleLogin = async () => {
    if (!mobile || !password) {
      Alert.alert(t('error'), t('enter_mobile') + ' & ' + t('enter_password'));
      return;
    }

    setLoading(true);
    try {
      await authContext.signIn(mobile, password);
    } catch (error) {
      Alert.alert(t('error'), error.message || t('connection_error'));
    } finally {
      setLoading(false);
    }
  };

  const toggleLanguage = async () => {
    const newLang = language === 'en' ? 'ur' : 'en';
    setLanguage(newLang);
    await authContext.setLanguage(newLang);
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>{t('app_name')}</Text>
        <Text style={styles.subtitle}>PNWHS bin Qasim</Text>
      </View>

      <View style={styles.form}>
        <Text style={styles.label}>{t('mobile')}</Text>
        <TextInput
          style={styles.input}
          placeholder={t('enter_mobile')}
          keyboardType="phone-pad"
          value={mobile}
          onChangeText={setMobile}
          editable={!loading}
        />

        <Text style={styles.label}>{t('password')}</Text>
        <TextInput
          style={styles.input}
          placeholder={t('enter_password')}
          secureTextEntry
          value={password}
          onChangeText={setPassword}
          editable={!loading}
        />

        <TouchableOpacity
          style={[styles.button, loading && styles.buttonDisabled]}
          onPress={handleLogin}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.buttonText}>{t('sign_in')}</Text>
          )}
        </TouchableOpacity>
      </View>

      <TouchableOpacity style={styles.languageButton} onPress={toggleLanguage}>
        <Text style={styles.languageText}>
          {language === 'en' ? t('urdu') : t('english')}
        </Text>
      </TouchableOpacity>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    backgroundColor: '#f5f5f5',
    justifyContent: 'center',
    padding: 20,
  },
  header: {
    alignItems: 'center',
    marginBottom: 40,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#1A5276',
  },
  subtitle: {
    fontSize: 14,
    color: '#666',
    marginTop: 8,
  },
  form: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 20,
    marginBottom: 20,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    marginBottom: 16,
    fontSize: 16,
  },
  button: {
    backgroundColor: '#1A5276',
    borderRadius: 8,
    padding: 14,
    alignItems: 'center',
    marginTop: 10,
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  languageButton: {
    alignItems: 'center',
    padding: 10,
  },
  languageText: {
    color: '#1A5276',
    fontSize: 14,
    fontWeight: '600',
  },
});

export default LoginScreen;
