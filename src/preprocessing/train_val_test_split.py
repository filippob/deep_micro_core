import numpy as np
from sklearn.model_selection import StratifiedGroupKFold
import pandas as pd


def split_summary(name, idx):
    return pd.Series(y[idx]).value_counts(normalize=True).rename(name)


def stratified_group_train_val_test_split(
    X,
    y,
    subject_ids,
    test_size=0.2,
    val_size=0.15,   # fraction of remaining train+val data
    random_state=42,
):
    X = np.asarray(X)
    y = np.asarray(y)
    groups = np.asarray(subject_ids)

    # test split
    n_splits_test = int(round(1 / test_size))

    sgkf_test = StratifiedGroupKFold(
        n_splits=n_splits_test,
        shuffle=True,
        random_state=random_state,
    )

    train_val_idx, test_idx = next(
        sgkf_test.split(X, y, groups)
    )

    # validation split from train_val
    X_tv = X[train_val_idx]
    y_tv = y[train_val_idx]
    groups_tv = groups[train_val_idx]

    n_splits_val = int(round(1 / val_size))

    sgkf_val = StratifiedGroupKFold(
        n_splits=n_splits_val,
        shuffle=True,
        random_state=random_state + 1,
    )

    inner_train_idx, inner_val_idx = next(
        sgkf_val.split(X_tv, y_tv, groups_tv)
    )

    train_idx = train_val_idx[inner_train_idx]
    val_idx = train_val_idx[inner_val_idx]

    return train_idx, val_idx, test_idx

if __name__ == "__main__":
    metadata_path = 'config/metadata/Metadata_IDs.csv'
    metadata_df = pd.read_csv(metadata_path)  

    metadata_df['Species/Substrate'] = metadata_df['Species/Substrate'].replace('food', 'cow')
    metadata_df["target"] = metadata_df["Species/Substrate"].astype(str) + "_" + metadata_df["Tissue"].astype(str)

    columns = metadata_df.columns
    subject_id_column = "subject_id"
    columns = columns.drop(subject_id_column)  
    target_column = "target"
    columns = columns.drop(target_column)
    
    X = metadata_df[columns].to_numpy()
    y = metadata_df[target_column].to_numpy()
    subject_ids = metadata_df[subject_id_column].to_numpy()

    for i in range(50):
        train_idx, val_idx, test_idx = stratified_group_train_val_test_split(
            X,
            y,
            subject_ids,
            test_size=0.2,
            val_size=0.125,   # 0.125 of remaining 80% = 10% overall
            random_state=i,
        )

        train_subjects = set(subject_ids[train_idx])
        val_subjects = set(subject_ids[val_idx])
        test_subjects = set(subject_ids[test_idx])

        assert train_subjects.isdisjoint(val_subjects)
        assert train_subjects.isdisjoint(test_subjects)
        assert val_subjects.isdisjoint(test_subjects)

        summary = pd.concat([
            split_summary("train", train_idx),
            split_summary("val", val_idx),
            split_summary("test", test_idx),
        ], axis=1)


        metadata_df[f"seed_{i}"] = ""
        metadata_df.loc[train_idx, f"seed_{i}"] = "train"
        metadata_df.loc[val_idx, f"seed_{i}"] = "val"
        metadata_df.loc[test_idx, f"seed_{i}"] = "test"

    print("Summary of splits across seeds:")
    print(summary)
    metadata_df.to_csv('config/metadata//Metadata_IDs_split.csv', index=False)