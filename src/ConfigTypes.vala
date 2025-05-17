/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020 Juan Pablo Lozano <libredeb@gmail.com>
 */

public enum ConfigType { INT, DOUBLE }

public struct ConfigField {
    public string group;
    public string key;
    public ConfigType type;
    public void* pointer;
}
