import React, { useState, useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { ActivityIndicator, View } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Screens
import LoginScreen from './screens/LoginScreen';
import DashboardScreen from './screens/DashboardScreen';
import ProfileScreen from './screens/ProfileScreen';
import ChallansScreen from './screens/ChallansScreen';
import VisitorPassesScreen from './screens/VisitorPassesScreen';
import ComplaintsScreen from './screens/ComplaintsScreen';
import NocScreen from './screens/NocScreen';

// Services
import api from './services/api';
import { setLanguage } from './services/i18n';

const Stack = createStackNavigator();

export default function App() {
  const [state, dispatch] = useState({
    isLoading: true,
    isSignout: false,
    userToken: null,
  });

  useEffect(() => {
    const bootstrapAsync = async () => {
      try {
        // Restore token and language
        const token = await AsyncStorage.getItem('userToken');
        const language = await AsyncStorage.getItem('language') || 'en';

        setLanguage(language);
        if (token) api.setToken(token);

        dispatch({ type: 'RESTORE_TOKEN', token });
      } catch (e) {
        console.log('Restoring token failed:', e);
      }
    };

    bootstrapAsync();
  }, []);

  const authContext = React.useMemo(
    () => ({
      signIn: async (mobile, password) => {
        try {
          const response = await api.login(mobile, password);
          const token = response.data.token;
          await AsyncStorage.setItem('userToken', token);
          api.setToken(token);
          dispatch({ type: 'SIGN_IN', token });
        } catch (error) {
          throw error;
        }
      },
      signOut: async () => {
        await AsyncStorage.removeItem('userToken');
        dispatch({ type: 'SIGN_OUT' });
      },
      setLanguage: async (lang) => {
        await AsyncStorage.setItem('language', lang);
        setLanguage(lang);
      },
    }),
    []
  );

  if (state.isLoading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <ActivityIndicator size="large" color="#1A5276" />
      </View>
    );
  }

  return (
    <NavigationContainer>
      <Stack.Navigator
        screenOptions={{
          headerStyle: {
            backgroundColor: '#1A5276',
          },
          headerTintColor: '#fff',
          headerTitleStyle: {
            fontWeight: 'bold',
          },
        }}
      >
        {state.userToken == null ? (
          <Stack.Screen
            name="Login"
            component={LoginScreen}
            options={{ headerShown: false }}
            initialParams={{ authContext }}
          />
        ) : (
          <>
            <Stack.Screen
              name="Dashboard"
              component={DashboardScreen}
              initialParams={{ authContext }}
            />
            <Stack.Screen name="Profile" component={ProfileScreen} />
            <Stack.Screen name="Challans" component={ChallansScreen} />
            <Stack.Screen name="VisitorPasses" component={VisitorPassesScreen} />
            <Stack.Screen name="Complaints" component={ComplaintsScreen} />
            <Stack.Screen name="Noc" component={NocScreen} />
          </>
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}
