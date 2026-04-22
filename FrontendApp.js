import "./App.css";
import { useMemo, useState } from "react";

const WEI_IN_ETH = 1_000_000_000_000_000_000n;

function formatEthFromWei(weiHex) {
  const wei = window.BigInt(weiHex);
  const whole = wei / WEI_IN_ETH;
  const fraction = wei % WEI_IN_ETH;
  const fractionDisplay = fraction
    .toString()
    .padStart(18, "0")
    .slice(0, 6)
    .replace(/0+$/, "");

  return fractionDisplay
    ? `${whole.toString()}.${fractionDisplay}`
    : whole.toString();
}

function App() {
  const [account, setAccount] = useState("");
  const [balance, setBalance] = useState("");
  const [chainId, setChainId] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const hasProvider = typeof window !== "undefined" && !!window.ethereum;

  const isConnected = useMemo(() => account.length > 0, [account]);

  const fetchBalance = async (address) => {
    const [weiBalance, activeChainId] = await Promise.all([
      window.ethereum.request({
        method: "eth_getBalance",
        params: [address, "latest"],
      }),
      window.ethereum.request({ method: "eth_chainId" }),
    ]);

    setBalance(formatEthFromWei(weiBalance));
    setChainId(activeChainId);
  };

  const connectWallet = async () => {
    if (!hasProvider) {
      setError("No wallet provider found. Install MetaMask to continue.");
      return;
    }

    setLoading(true);
    setError("");

    try {
      const accounts = await window.ethereum.request({
        method: "eth_requestAccounts",
      });

      if (!accounts?.length) {
        throw new Error("No account returned by wallet.");
      }

      const selectedAccount = accounts[0];
      setAccount(selectedAccount);
      await fetchBalance(selectedAccount);
    } catch (requestError) {
      setError(requestError.message || "Failed to connect wallet.");
    } finally {
      setLoading(false);
    }
  };

  const refreshBalance = async () => {
    if (!account) {
      return;
    }

    setLoading(true);
    setError("");

    try {
      await fetchBalance(account);
    } catch (requestError) {
      setError(requestError.message || "Failed to refresh balance.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="app-shell">
      <main className="wallet-card">
        <h1>Crypto Wallet Balance</h1>
        <p className="subtitle">
          Connect your wallet and inspect your native token balance.
        </p>

        {!isConnected ? (
          <button type="button" onClick={connectWallet} disabled={loading}>
            {loading ? "Connecting..." : "Connect Wallet"}
          </button>
        ) : (
          <div className="wallet-details">
            <p>
              <span>Address</span>
              <strong>{account}</strong>
            </p>
            <p>
              <span>Network</span>
              <strong>{chainId}</strong>
            </p>
            <p>
              <span>Balance</span>
              <strong>{balance} ETH</strong>
            </p>
            <button type="button" onClick={refreshBalance} disabled={loading}>
              {loading ? "Refreshing..." : "Refresh Balance"}
            </button>
          </div>
        )}

        {!hasProvider ? (
          <p className="info">
            Wallet extension not detected. Install MetaMask and reload this
            page.
          </p>
        ) : null}

        {error ? <p className="error">{error}</p> : null}
      </main>
    </div>
  );
}

export default App;
