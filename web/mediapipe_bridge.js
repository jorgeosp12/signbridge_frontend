(function () {
  const FACE_SUBSET = Array.from({ length: 68 }, (_, index) => index);
  const KEYPOINT_DIM = 429;
  const FEATURE_DIM = 858;
  const EMPTY_FEATURES = new Array(FEATURE_DIM).fill(0);
  const SEND_TIMEOUT_MS = 800;

  function pushLandmarks(target, landmarks, expectedCount, subset) {
    if (!landmarks) {
      const missing = subset ? subset.length : expectedCount;
      for (let i = 0; i < missing * 3; i += 1) {
        target.push(0);
      }
      return;
    }

    if (subset) {
      subset.forEach((index) => {
        const landmark = landmarks[index];
        if (!landmark) {
          target.push(0, 0, 0);
          return;
        }
        target.push(landmark.x || 0, landmark.y || 0, landmark.z || 0);
      });
      return;
    }

    for (let i = 0; i < expectedCount; i += 1) {
      const landmark = landmarks[i];
      if (!landmark) {
        target.push(0, 0, 0);
      } else {
        target.push(landmark.x || 0, landmark.y || 0, landmark.z || 0);
      }
    }
  }

  function buildKeypoints(results) {
    const keypoints = [];

    pushLandmarks(keypoints, results.leftHandLandmarks, 21);
    pushLandmarks(keypoints, results.rightHandLandmarks, 21);
    pushLandmarks(keypoints, results.faceLandmarks, 0, FACE_SUBSET);
    pushLandmarks(keypoints, results.poseLandmarks, 33);

    if (keypoints.length !== KEYPOINT_DIM) {
      throw new Error(`Invalid keypoint length: ${keypoints.length} (expected ${KEYPOINT_DIM})`);
    }

    return keypoints;
  }

  function computeFeatures(session, results) {
    const safeResults = results || {};
    const keypoints = buildKeypoints(safeResults);
    const handsVisible = Boolean(
      safeResults.leftHandLandmarks || safeResults.rightHandLandmarks
    );

    let velocity;
    if (session.prevKeypoints && session.prevKeypoints.length === keypoints.length) {
      velocity = keypoints.map((value, index) => value - session.prevKeypoints[index]);
    } else {
      velocity = new Array(KEYPOINT_DIM).fill(0);
    }

    session.prevKeypoints = keypoints.slice();
    const features = keypoints.concat(velocity);
    if (features.length !== FEATURE_DIM) {
      throw new Error(`Invalid feature length: ${features.length} (expected ${FEATURE_DIM})`);
    }

    return {
      features,
      handsVisible,
    };
  }

  function createSession(videoElement) {
    if (typeof Holistic === "undefined") {
      throw new Error("MediaPipe Holistic is not loaded.");
    }
    if (!videoElement) {
      throw new Error("Video element is required to create a MediaPipe session.");
    }

    const holistic = new Holistic({
      locateFile: (file) =>
        `https://cdn.jsdelivr.net/npm/@mediapipe/holistic/${file}`,
    });

    holistic.setOptions({
      modelComplexity: 1,
      smoothLandmarks: true,
      refineFaceLandmarks: false,
      minDetectionConfidence: 0.3,
      minTrackingConfidence: 0.5,
    });

    const session = {
      holistic,
      prevKeypoints: null,
      latestExtraction: {
        features: EMPTY_FEATURES.slice(),
        handsVisible: false,
      },
      busy: false,
      disposed: false,
      rafId: null,
      videoElement,
    };

    holistic.onResults((results) => {
      try {
        session.latestExtraction = computeFeatures(session, results);
      } catch (_) {
        session.latestExtraction = {
          features: EMPTY_FEATURES.slice(),
          handsVisible: false,
        };
      }
    });

    const sendWithTimeout = (sessionRef) => {
      return Promise.race([
        sessionRef.holistic.send({ image: sessionRef.videoElement }),
        new Promise((_, reject) => {
          window.setTimeout(() => reject(new Error("Holistic send timeout")), SEND_TIMEOUT_MS);
        }),
      ]);
    };

    const processLoop = async () => {
      if (session.disposed) {
        return;
      }

      if (
        !session.busy &&
        session.videoElement.readyState >= 2 &&
        session.videoElement.videoWidth > 0 &&
        session.videoElement.videoHeight > 0
      ) {
        session.busy = true;
        try {
          await sendWithTimeout(session);
        } catch (_) {
          session.latestExtraction = {
            features: EMPTY_FEATURES.slice(),
            handsVisible: false,
          };
        } finally {
          session.busy = false;
        }
      }

      session.rafId = window.requestAnimationFrame(processLoop);
    };

    session.rafId = window.requestAnimationFrame(processLoop);
    return session;
  }

  function getLatestExtraction(session) {
    if (!session || !session.holistic) {
      throw new Error("MediaPipe session is not initialized.");
    }

    return (
      session.latestExtraction || {
        features: EMPTY_FEATURES.slice(),
        handsVisible: false,
      }
    );
  }

  function disposeSession(session) {
    if (!session) {
      return;
    }
    session.disposed = true;
    if (session.rafId !== null) {
      window.cancelAnimationFrame(session.rafId);
      session.rafId = null;
    }
    if (session.holistic && typeof session.holistic.close === "function") {
      session.holistic.close();
    }
  }

  function speakText(text) {
    if (!("speechSynthesis" in window)) {
      return false;
    }

    const cleanedText = (text || "").trim();
    if (!cleanedText) {
      return false;
    }

    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(cleanedText);
    utterance.lang = "en-US";
    utterance.rate = 1.0;
    utterance.pitch = 1.0;
    window.speechSynthesis.speak(utterance);
    return true;
  }

  window.signBridgeMp = {
    createSession,
    getLatestExtraction,
    disposeSession,
    speakText,
  };
})();
