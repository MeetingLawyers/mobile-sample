import { useEffect, useState } from 'react';
import {
  IonButton,
  IonContent,
  IonHeader,
  IonIcon,
  IonInput,
  IonItem,
  IonList,
  IonNote,
  IonPage,
  IonTitle,
  IonToolbar,
} from '@ionic/react';
import { chatbubblesOutline, logInOutline, logOutOutline, peopleOutline } from 'ionicons/icons';

import { MeetingLawyers } from '../plugins/meeting-lawyers';
import { ML_API_KEY, ML_ENVIRONMENT, ML_THEME, ML_USER_ID } from '../config/constants';
import './Home.css';

type SdkStatus = 'missing-credentials' | 'configuring' | 'configured' | 'authenticated';

const Home: React.FC = () => {
  const [status, setStatus] = useState<SdkStatus>('configuring');
  const [error, setError] = useState<string | null>(null);
  const [professionalHash, setProfessionalHash] = useState('');

  useEffect(() => {
    configureSdk();
  }, []);

  const configureSdk = async () => {
    if (!ML_API_KEY || !ML_USER_ID) {
      setStatus('missing-credentials');
      return;
    }
    try {
      setError(null);
      await MeetingLawyers.configure({ apiKey: ML_API_KEY, environment: ML_ENVIRONMENT });
      await MeetingLawyers.configureTheme(ML_THEME);
      const { authenticated } = await MeetingLawyers.isAuthenticated();
      setStatus(authenticated ? 'authenticated' : 'configured');
    } catch (e) {
      setStatus('missing-credentials');
      setError(describe(e));
    }
  };

  const signIn = async () => {
    try {
      setError(null);
      await MeetingLawyers.authenticate({ userId: ML_USER_ID });
      setStatus('authenticated');
      // Asks for push permission and links the token to the user; a push failure never blocks sign-in.
      MeetingLawyers.registerForPushNotifications().catch(() => undefined);
    } catch (e) {
      setError(describe(e));
    }
  };

  const openProfessionalList = async () => {
    try {
      setError(null);
      await MeetingLawyers.openProfessionalList();
    } catch (e) {
      setError(describe(e));
    }
  };

  const openChat = async () => {
    try {
      setError(null);
      await MeetingLawyers.openChatWithProfessional({ professionalHash });
    } catch (e) {
      setError(describe(e));
    }
  };

  const logOut = async () => {
    try {
      setError(null);
      await MeetingLawyers.logout();
      setStatus('configured');
    } catch (e) {
      setError(describe(e));
    }
  };

  return (
    <IonPage>
      <IonHeader>
        <IonToolbar>
          <IonTitle>MeetingLawyers Sample</IonTitle>
        </IonToolbar>
      </IonHeader>
      <IonContent fullscreen className="ion-padding">
        <p data-testid="sdk-status">
          Status: <strong>{describeStatus(status)}</strong> ({ML_ENVIRONMENT})
        </p>
        {status === 'missing-credentials' && (
          <IonNote color="warning">
            Fill in ML_API_KEY and ML_USER_ID in the repo-root <code>.env</code>, then rebuild.
          </IonNote>
        )}
        {error && (
          <IonNote color="danger" data-testid="sdk-error">
            {error}
          </IonNote>
        )}

        <IonList inset={false}>
          <IonButton
            expand="block"
            onClick={signIn}
            disabled={status !== 'configured'}
            data-testid="sign-in"
          >
            <IonIcon slot="start" icon={logInOutline} />
            Sign in
          </IonButton>

          <IonButton
            expand="block"
            onClick={openProfessionalList}
            disabled={status !== 'authenticated'}
            data-testid="open-list"
          >
            <IonIcon slot="start" icon={peopleOutline} />
            Open professional list
          </IonButton>

          <IonItem>
            <IonInput
              label="Professional hash"
              labelPlacement="stacked"
              placeholder="Optional: open a chat directly"
              value={professionalHash}
              onIonInput={(e) => setProfessionalHash(e.detail.value ?? '')}
            />
          </IonItem>
          <IonButton
            expand="block"
            fill="outline"
            onClick={openChat}
            disabled={status !== 'authenticated' || !professionalHash}
            data-testid="open-chat"
          >
            <IonIcon slot="start" icon={chatbubblesOutline} />
            Open chat with professional
          </IonButton>

          <IonButton
            expand="block"
            fill="clear"
            color="medium"
            onClick={logOut}
            disabled={status !== 'authenticated'}
            data-testid="log-out"
          >
            <IonIcon slot="start" icon={logOutOutline} />
            Log out
          </IonButton>
        </IonList>
      </IonContent>
    </IonPage>
  );
};

/// Human-readable label for each SDK status.
const describeStatus = (status: SdkStatus): string => {
  switch (status) {
    case 'missing-credentials':
      return 'Missing credentials';
    case 'configuring':
      return 'Configuring…';
    case 'configured':
      return 'Configured';
    case 'authenticated':
      return 'Authenticated';
  }
};

/// Extracts a readable message from a plugin error.
const describe = (error: unknown): string =>
  error instanceof Error ? error.message : String(error);

export default Home;
