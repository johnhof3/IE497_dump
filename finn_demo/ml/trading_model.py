import torch
import torch.nn as nn
import time


if torch.cuda.is_available():
    device = torch.device("cuda")
    print("using cuda")
elif torch.backends.mps.is_available():
    device = torch.device("mps")
    print("using mps")
else:
    device = torch.device("cpu")
    print("using cpu")

x = torch.ones(1, device=device)
print(x)
    
    
class OrderFlowCNNLSTM(nn.Module):
    def __init__(self):
        super(OrderFlowCNNLSTM, self).__init__()
        
        self.conv_blocks = nn.Sequential(
            # block 2
            nn.Conv2d(in_channels=1, out_channels=32, kernel_size=(1,2), stride=(1,2)),
            nn.LeakyReLU(.01),
            nn.Conv2d(in_channels=32, out_channels=32, kernel_size=(4,1), stride=(1,1), padding=(3,0)),
            nn.LeakyReLU(.01),
            nn.Conv2d(in_channels=32, out_channels=32, kernel_size=(4,1), stride=(1,1)),
            nn.LeakyReLU(.01),
            # block 3
            nn.Conv2d(in_channels=32, out_channels=32, kernel_size=(1,10), stride=(1,10)), # gets kernel dimensions wrong in paper (1,10) vs (10,1)
            nn.LeakyReLU(.01)
        )
        
        #block 4: inception      
        self.inception_1 = nn.Sequential(
            nn.Conv2d(in_channels=32, out_channels=64, kernel_size=(1,1)),
            nn.LeakyReLU(.01),
            nn.Conv2d(in_channels=64, out_channels=64, kernel_size=(3,1), stride=(1,1), padding=(1,0)),
            nn.LeakyReLU(.01)
        )
        
        self.inception_2 = nn.Sequential(
            nn.Conv2d(in_channels=32, out_channels=64, kernel_size=(1,1)),
            nn.LeakyReLU(.01),
            nn.Conv2d(in_channels=64, out_channels=64, kernel_size=(5,1), stride=(1,1), padding=(2,0)),
            nn.LeakyReLU(.01)
        )
        
        self.inception_3 = nn.Sequential(
            nn.MaxPool2d(kernel_size=(3,1), stride=(1,1), padding=(1,0)), # same parameters as Zhang paper
            nn.Conv2d(in_channels=32, out_channels=64, kernel_size=(1,1), stride=(1,1)),
            nn.LeakyReLU(.01)
        )
        
        self.lstm = nn.LSTM(input_size=192, hidden_size=64, batch_first=True)
        self.dense = nn.Linear(64, 10)
        
        
    def forward(self, x):
    
        x = self.conv_blocks(x)
        
        inception_1 = self.inception_1(x)
        inception_2 = self.inception_2(x)
        inception_3 = self.inception_3(x)
        
        inception = torch.cat([inception_1, inception_2, inception_3], dim=1)
        inception = inception.squeeze(-1).permute(0, 2, 1)
        
        x = self.lstm(inception)[0]
        x = self.dense(x[:, -1, :])
        
        return x
    
    
def train(model, train_loader, optimizer, criterion, epochs):
    for epoch in range(epochs):
        for data, target in train_loader:
            optimizer.zero_grad()
            output = model(data)
            loss = criterion(output, target)
            loss.backward()
            optimizer.step()
        print(f'Epoch {epoch+1}/{epochs}, Loss: {loss.item()}')
    return model