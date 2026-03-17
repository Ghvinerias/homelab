import http from 'k6/http';

const targetUrl = __ENV.TARGET_URL || 'https://echo.test.slick.ge';
const runId = __ENV.RUN_ID || `run-${Date.now()}`;

function getHost(url) {
  const match = url.match(/^[a-zA-Z][a-zA-Z\d+.-]*:\/\/([^/?#]+)/);
  return match ? match[1] : 'unknown-target';
}

function getPath(url) {
  const match = url.match(/^[a-zA-Z][a-zA-Z\d+.-]*:\/\/[^/?#]+([^?#]*)/);
  if (!match || !match[1]) {
    return '/';
  }
  return match[1] === '' ? '/' : match[1];
}

const endpoint = getPath(targetUrl);

export const options = {
  discardResponseBodies: true,
  noConnectionReuse: false,
  noVUConnectionReuse: false,
  scenarios: {
    fixed_10k_rps: {
      executor: 'constant-arrival-rate',
      rate: Number(__ENV.RATE || 10000),
      timeUnit: '1s',
      duration: __ENV.DURATION || '5m',
      preAllocatedVUs: Number(__ENV.PRE_ALLOCATED_VUS || 3000),
      maxVUs: Number(__ENV.MAX_VUS || 12000),
      gracefulStop: '10s',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
  },
  tags: {
    test_name: __ENV.TEST_NAME || 'echo-extreme',
    target: getHost(targetUrl),
    env: __ENV.ENVIRONMENT || 'infra',
    run_id: runId,
  },
};

export default function () {
  http.get(targetUrl, {
    timeout: __ENV.REQUEST_TIMEOUT || '2s',
    tags: { endpoint },
  });
}
