import type { LobbiesConfig } from "@src/config";
import { InvalidCommandError, LimitError } from "@src/errors";
import { rootLogger } from "@src/logger";
import type { SessionData } from "@src/sessions/session";
import { nanoid } from "nanoid";
import {
  type Lobby,
  requireLobbyJoinable,
  requireLobbyModifiableIn,
} from "./lobby";
import type { LobbyEventBus } from "./lobby.events";
import type { LobbyRepository } from "./lobby.repository";

export class LobbyService {
  private logger = rootLogger.child({ name: "LobbyService" });

  constructor(
    private repository: LobbyRepository,
    private config: LobbiesConfig,
    private eventBus: LobbyEventBus
  ) {}

  create(
    address: string,
    data: Map<string, string>,
    session: SessionData
  ): Lobby {
    this.logger.info(
      { data: Object.fromEntries(data.entries()), address },
      "Creating lobby with custom data"
    );

    if (session.gameId === undefined && !this.config.enableGameless)
      throw new InvalidCommandError("Can't create lobbies without a game!");

    if (
      this.config.maxCount > 0 &&
      this.repository.count() >= this.config.maxCount
    )
      throw new LimitError(
        `Can't host more than ${this.config.maxCount} active lobbies on this instance!`
      );

    if (
      this.config.maxPerSession > 0 &&
      this.repository.countBySession(session.id) >= this.config.maxPerSession
    )
      throw new LimitError(
        `Session can't have more than ${this.config.maxPerSession} active lobbies!`
      );

    if (
      this.config.maxDataEntries > 0 &&
      data.size > this.config.maxDataEntries
    )
      throw new LimitError(
        `Lobbies can't have more than ${this.config.maxDataEntries} data entries!`
      );

    const lobby: Lobby = {
      id: this.generateId(),
      address,
      gameId: session.gameId,
      owner: session.id,
      isVisible: true,
      isLocked: false,
      sessions: new Map([[session.id, session]]),
      data,
    };

    this.repository.add(lobby);
    this.eventBus.emit("lobby-create", lobby);

    this.logger.info(
      { session, lobby },
      "Lobby#%s created, bound to session#%s",
      lobby.id,
      session.id
    );
    return lobby;
  }

  delete(lobby: Lobby, session: SessionData) {
    requireLobbyModifiableIn(lobby, session);
    this.repository.remove(lobby.id);
    this.eventBus.emit("lobby-delete", lobby);
  }

  join(lobby: Lobby, session: SessionData): string {
    requireLobbyJoinable(lobby, session);
    lobby.sessions.set(session.id, session);

    this.repository.update(lobby);
    return [...lobby.sessions.keys()].join(", ");
  }

  leave(lobby: Lobby, session: SessionData): string {
    // requireLobbyJoinable(lobby, session); NO CHECKS on leaving
    lobby.sessions.delete(session.id);
    this.repository.update(lobby);

    return [...lobby.sessions.keys()].join(", ");
  }

  setData(
    lobby: Lobby,
    data: Map<string, string>,
    session: SessionData
  ): Lobby {
    requireLobbyModifiableIn(lobby, session);

    if (
      this.config.maxDataEntries > 0 &&
      data.size > this.config.maxDataEntries
    )
      throw new LimitError(
        `Lobbies can't have more than ${this.config.maxDataEntries} data entries!`
      );

    const updated = { ...lobby, data };
    this.repository.update(updated);
    return updated;
  }

  lock(lobby: Lobby, session: SessionData): Lobby {
    requireLobbyModifiableIn(lobby, session);

    const result: Lobby = { ...lobby, isLocked: true };
    this.repository.update(result);
    this.eventBus.emit("lobby-change", lobby, result);
    return result;
  }

  unlock(lobby: Lobby, session: SessionData): Lobby {
    requireLobbyModifiableIn(lobby, session);

    const result: Lobby = { ...lobby, isLocked: false };
    this.repository.update(result);
    this.eventBus.emit("lobby-change", lobby, result);
    return result;
  }

  hide(lobby: Lobby, session: SessionData): Lobby {
    requireLobbyModifiableIn(lobby, session);

    const result: Lobby = { ...lobby, isVisible: false };
    this.repository.update(result);
    this.eventBus.emit("lobby-change", lobby, result);
    return result;
  }

  publish(lobby: Lobby, session: SessionData): Lobby {
    requireLobbyModifiableIn(lobby, session);

    const result: Lobby = { ...lobby, isVisible: true };
    this.repository.update(result);
    this.eventBus.emit("lobby-change", lobby, result);
    return result;
  }

  // NOTE: Kickoff
  start(lobby: Lobby, session: SessionData): String {
    requireLobbyModifiableIn(lobby, session);

    // const result: Lobby = { ...lobby, isVisible: false };
    // this.repository.update(result);
    // this.eventBus.emit("lobby-change", lobby, result);

    this.logger.info(
      { session, lobby },
      "Lobby#%s started, bound to session#%s",
      lobby.id,
      [...lobby.sessions.keys()].join(", ")
    );

    this.eventBus.emit(
      "lobby-start",
      lobby,
      [...lobby.sessions.keys()].join(", ")
    );

    return [...lobby.sessions.keys()].join(", ");
  }

  private generateId(): string {
    return nanoid(this.config.idLength);
  }
}
